class ProfessionalsController < BackofficeController
    #before_action :get_new_contact_url, only: [:edit]
    before_action :set_tab, only: [:index, :new,:create, :edit ]
    before_action :get_lists, except: [:search]

    layout "backoffice"
    add_breadcrumb I18n.t("breadcrumb_navigation.home"), :root_path

    def index
        add_breadcrumb I18n.t("breadcrumb_navigation.data_base_main_page"), db_main_page_path
        add_breadcrumb I18n.t("breadcrumb_navigation.professionals_index")
    end

    def new
        @professional = Onepharma::Professional.new
        @professional_details= @professional.professional_details.build
        @professional_specialties= @professional.specialties.build

        add_breadcrumb I18n.t("breadcrumb_navigation.data_base_main_page"), db_main_page_path
        add_breadcrumb I18n.t("breadcrumb_navigation.new_professional")
    end

    def create
        Onepharma::Professional.transaction do
            @professional = Onepharma::Professional.create(professional_params)
            @professional.specialties[0].SPECIALTY_RANK = 1
        end

        if @professional.save
            flash[:success] = I18n.t("alerts.records.professional_created")
            redirect_to(edit_professional_path(@professional.id))
        else
            flash.now[:error] = I18n.t("alerts.records.erro_check_the_fields")
            render 'new'
        end
    end


    def edit
        @professional = Onepharma::Professional.where(CUSTOMER_ID: params[:id])[0]

        @departments_cache = @professional.load_affiliation_info
        #@professional = Onepharma::Professional.includes(:professional_details).where(CUSTOMER_ID: params[:id])[0]
        @professional_details = @professional.professional_details[0]
        if !@professional_details.present?
            @professional_details = @professional.professional_details.create!(PREFIX: "0", TITLE:"0", GENDER:"0")
        end

        #tickets - precisam de um main_object id, devido aos erros e para persistir a designação da variavel
        if current_user.can_do?("manage_tickets")
            @object_open_tickets = @professional.tickets.by_open.order(:created_at) || 0
        elsif current_user.can_do?("manage_only_team_tickets")
            @object_open_tickets = @professional.tickets.by_open.by_team(current_user.active_team).order(:created_at) || 0
        elsif current_user.can_do?("create_tickets")
            @object_open_tickets = @professional.tickets.by_open.where(user_id: current_user.id).order(:created_at) || 0
        end

        @ticket_object_id = @professional.CUSTOMER_ID

        @new_competency = Onepharma::Competency.new
        @new_specialty = Onepharma::Specialty.new
        @new_contact = Onepharma::Contact.new
        @new_prof_dept_affiliations = Onepharma::ProfDeptAffiliation.new
        #@record_note = RecordNote.find_by(object_id: @professional.CUSTOMER_ID)
        @record_note = RecordNote.find_or_initialize_by(belong_to_object_id: @professional.CUSTOMER_ID)
        #change reason - foi adicionado uma change reason à lista que nao existe no opdb
        @status_change_reason_value =
        if (@professional.STATUS_CHANGE_REASON == "5") && (@professional.STATUS == "ACTV")
            "12"
        else
            @professional.STATUS_CHANGE_REASON
        end

        get_new_contact_url()

        @departments_list_hash = @professional.departments.index_by(&:CUSTOMER_ID)

        add_breadcrumb I18n.t("breadcrumb_navigation.data_base_main_page"), db_main_page_path
        add_breadcrumb I18n.t("breadcrumb_navigation.edit_professional")
    end

    def update
        @professional = Onepharma::Professional.where(CUSTOMER_ID: params[:id])[0]
        @professional_details = Onepharma::ProfessionalDetail.where(CUSTOMER_ID: params[:id])[0]
        @departments_list_hash = @professional.departments.index_by(&:CUSTOMER_ID)

        @status_change_reason_value =
        if (@professional.STATUS_CHANGE_REASON == "5") && (@professional.STATUS == "ACTV")
            "12"
        else
            @professional.STATUS_CHANGE_REASON
        end

        if @professional.update(professional_params) && @professional_details.update(professional_details_params)
            if !["ACTV", "DVL"].include?(@professional.STATUS)
                #@professional.prof_dept_affiliations.where(STATUS: ["ACTV"]).update(STATUS: @professional.STATUS)
                @professional.prof_dept_affiliations.where(STATUS: "ACTV").find_each do |affiliation|
                    affiliation.update_columns(STATUS: @professional.STATUS)
                    affiliation.touch
                end
            end
            flash.now[:success] = I18n.t("alerts.records.professional_updated")
        else
            flash.now[:error] = I18n.t("alerts.records.erro_check_the_fields")
        end
    end

    def search
        @new_prof_dept_affiliation = Onepharma::ProfDeptAffiliation.new
        if params[:search][:num_ordem].blank? && params[:search][:customer_id].blank? && params[:search][:full_name].blank? && params[:search][:specialty].blank?
            flash.now[:error] = I18n.t("alerts.empty_fields")
            return
        elsif params[:search][:num_ordem].blank? && params[:search][:customer_id].blank? && params[:search][:specialty].blank? && params[:search][:full_name].length < 3
            flash.now[:error] = I18n.t("alerts.full_name_too_short")
            return
        elsif !params[:search][:num_ordem].blank? && params[:search][:num_ordem].length < 3
            flash.now[:error] = I18n.t("alerts.num_ordem_too_short")
            return
        #elsif !params[:search][:num_ordem].blank? && !params[:search][:num_ordem].to_s.match?(/\A\d+\z/)
        #    flash.now[:error] = I18n.t("alerts.must_be_number")
        #    return
        #elsif !params[:search][:customer_id].blank? && !params[:search][:customer_id].to_s.match?(/\A\d+\z/)
        #    flash.now[:error] = I18n.t("alerts.must_be_number")
        #    return
        end

        #begin
            @professionals_search_results = Onepharma::Professional.search_with(params[:search])

            #para limitar o load dos elementos
            #if @professionals_search_results.length > 500
            #    flash.now[:error] = I18n.t("alerts.too_much_results")
            #    @professionals_search_results = []
            #    return
            #end

            searchCustomerStruct = Struct.new(:customer_id, :full_name, :external_id_1, :specialties, :affiliations)

            #aux = @professionals_search_results.eager_load(:active_affiliation_departments).each_with_object({}) do |prof, hash|
            aux = @professionals_search_results.each_with_object({}) do |prof, hash|
                if(hash.has_key?(prof.CUSTOMER_ID))
                    hash[prof.CUSTOMER_ID].specialties += " | #{prof.specialty}"
                else
                    hash[prof.CUSTOMER_ID] = searchCustomerStruct.new(prof.CUSTOMER_ID, prof.FULL_NAME, prof.EXTERNAL_ID_1, prof.specialty || "")
                end

                #lista de affiliacoes
                next unless hash[prof.CUSTOMER_ID][:affiliations].nil?

                hash[prof.CUSTOMER_ID][:affiliations] = []
                hash[prof.CUSTOMER_ID][:affiliations] = prof.active_affiliation_departments.pluck(:FIRST_NAME)
            end

            @professionals_search_results = aux.values
            @department = Onepharma::Department.where(CUSTOMER_ID: params[:department_id])[0]
            @institution = @department.institution

        #rescue ActiveRecord::StatementTimeout, TinyTds::Error => e
        #    flash[:error] = I18n.t("alerts.too_much_results")
        #    @professionals_search_results=[]
        #    return
        #end

        #para check do profissional no departamento
        @professionals_from_department_ids = @department.professionals.pluck(:CUSTOMER_ID)

        #Listas
        #lista de cargos
        @affiliation_roles_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'person.affiliation_role').where(EXCLUDE: nil).order(:DESCRIPTION).pluck :DESCRIPTION, :CODE
        #lista deowners
        @affiliation_owners_list_for_select = OpcMaster::OpcCompany.where(company_id: [9, 20]).pluck :name, :company_id

        #hash de cargos
        @affiliation_roles_list_hash = @affiliation_roles_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }
        #hash de owners
        @affiliation_owners_list_hash = @affiliation_owners_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }
    end

    def index_search
        if params[:search][:num_ordem].blank? && params[:search][:customer_id].blank?
            if params[:search][:full_name].blank? && params[:search][:specialty].blank?
                flash.now[:error] = I18n.t("alerts.empty_fields")
                return
            end
        elsif params[:search][:num_ordem].blank? && params[:search][:customer_id].blank? && params[:search][:specialty].blank? && params[:search][:full_name].length < 3
            flash.now[:error] = I18n.t("alerts.full_name_too_short")
            return
        elsif !params[:search][:num_ordem].blank? && params[:search][:num_ordem].length < 3
            flash.now[:error] = I18n.t("alerts.num_ordem_too_short")
            return
        #elsif !params[:search][:num_ordem].blank? && !params[:search][:num_ordem].to_s.match?(/\A\d+\z/)
        #    flash.now[:error] = I18n.t("alerts.must_be_number")
        #    return
        #elsif !params[:search][:customer_id].blank? && !params[:search][:customer_id].to_s.match?(/\A\d+\z/)
        #    flash.now[:error] = I18n.t("alerts.must_be_number")
        #    return
        end

        #begin
            @professionals_search_results = Onepharma::Professional.index_search_with(params[:search])
            searchCustomerStruct = Struct.new(:customer_id, :status, :full_name, :external_id_1, :specialties, :affiliations)

            aux = @professionals_search_results.each_with_object({}) do |prof, hash|
                if(hash.has_key?(prof.CUSTOMER_ID))
                    hash[prof.CUSTOMER_ID].specialties += " | #{prof.specialty}"
                else
                    hash[prof.CUSTOMER_ID] = searchCustomerStruct.new(prof.CUSTOMER_ID, prof.STATUS, prof.FULL_NAME, prof.EXTERNAL_ID_1, prof.specialty || "")
                end

                #lista de affiliacoes
                next unless hash[prof.CUSTOMER_ID][:affiliations].nil?
                hash[prof.CUSTOMER_ID][:affiliations] = []
                hash[prof.CUSTOMER_ID][:affiliations] = prof.active_affiliation_departments.pluck(:FIRST_NAME)
            end
            @professionals_search_results = aux.values

        #rescue ActiveRecord::StatementTimeout, TinyTds::Error => e
        #    flash[:error] = I18n.t("alerts.too_much_results")
        #    @professionals_search_results=[]
        #    return
        #end
    end

    private
    def set_tab
        @tab = :professionals
    end

    def professional_params
        params.require(:onepharma_professional).permit(:STATUS_CHANGE_REASON, :FIRST_NAME, :LAST_NAME, :FULL_NAME, :SHORT_NAME, :CUSTOMER_TYPE, :CUSTOMER_SUB_TYPE, :EXTERNAL_ID_1, professional_details_attributes: [:PREFIX, :TITLE, :GENDER, :BIRTH_DATE], specialties_attributes: [:SPECIALTY, :SPECIALTY_RANK])
    end

    def professional_details_params
        #birth_date com formato de data na bd
        params.require(:onepharma_professional)
            .require(:onepharma_professional_detail)
            .permit(:PREFIX, :TITLE, :GENDER, :BIRTH_DATE)
    end

    def get_new_contact_url
        #url para form professionals/contacts
        @professional= Onepharma::Professional.where(CUSTOMER_ID: params[:id])[0]
        @new_contact_url = professional_contacts_path(@professional.CUSTOMER_ID)
    end

    def get_lists
        #lista de tipos validação
        @validation_type_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'validation.change_reason').order(DESCRIPTION: :asc).pluck :DESCRIPTION, :CODE
        @validation_type_list_for_select << [I18n.t("label_professionals.status_valid_retired"), 12]

        #lista de tipos
        @professional_type_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'person.type').order(DESCRIPTION: :asc).pluck :DESCRIPTION, :CODE

        #lista de subtipos
        @professional_sub_type_list_for_select = Onepharma::TableOfValue.by_professional_sub_type

        #lista de prefixo
        @professional_details_prefix_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'person.prefix').pluck :DESCRIPTION, :CODE

        #lista de titulo
        @professional_details_title_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'person.title').pluck :DESCRIPTION, :CODE

        #lista de titulo
        @professional_details_gender_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'person.gender').pluck :DESCRIPTION, :CODE

        #lista de especialidades
        @specialties_list_for_select = Onepharma::TableOfValue.specialties_list_for_select
        #hash de especialidades
        @specialties_list_hash = @specialties_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }

        #lista de competencias
        @competencies_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'person.valencia').order(DESCRIPTION: :asc).pluck :DESCRIPTION, :CODE
        #hash de competencias
        @competencies_list_hash = @competencies_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }

        #lista de cargos
        @affiliation_roles_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'person.affiliation_role').where(EXCLUDE: nil).order(DESCRIPTION: :asc).pluck :DESCRIPTION, :CODE
        #hash de cargos
        @affiliation_roles_list_hash = @affiliation_roles_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }

        #lista deowners
        @affiliation_owners_list_for_select = OpcMaster::OpcCompany.where(company_id: [9, 20]).pluck :name, :company_id
        #hash de owners
        @affiliation_owners_list_hash = @affiliation_owners_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }

        @institution_list_for_select = Onepharma::Institution.by_active.pluck(:FULL_NAME, :CUSTOMER_ID)

        #histórico
        @log_record_activity_list = LogRecord.get_by_object_id(params[:id])
        get_user_email_list
    end

    def get_user_email_list
        @users_email = {}
        User.all.each do |user|
            @users_email[user.id] = user.name
        end
    end

end
