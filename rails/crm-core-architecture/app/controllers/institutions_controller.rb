class InstitutionsController < BackofficeController
    before_action :get_lists, only: [:new, :create, :edit, :update, :inst_dept_prof_affiliations_section_table]
    before_action :set_tab, only: [:index, :new, :create, :edit]
    layout "backoffice"
    add_breadcrumb I18n.t("breadcrumb_navigation.home"), :root_path

    def index
        @institution_sub_type_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'institution.sub_type').pluck :DESCRIPTION, :CODE
        @institution_PA_CITY_list_for_select = Onepharma::Address.by_active.distinct.pluck :PA_CITY

        add_breadcrumb I18n.t("breadcrumb_navigation.data_base_main_page"), db_main_page_path
        add_breadcrumb I18n.t("breadcrumb_navigation.institutions_index")
    end

    def new
        @institution = Onepharma::Institution.new
        @address = @institution.addresses.build(PA_CP3: "")
        @institution_info= @institution.institution_info.build

        add_breadcrumb I18n.t("breadcrumb_navigation.data_base_main_page"), db_main_page_path
        add_breadcrumb I18n.t("breadcrumb_navigation.new_institution")
    end

    def create
        Onepharma::Institution.transaction do
            @institution = Onepharma::Institution.new(institution_params)

            if @institution.save
                flash[:success] = I18n.t("alerts.records.institution_created")
                redirect_to edit_institution_path(@institution)
            else
                flash.now[:error] = I18n.t("alerts.records.error_check_the_fields")
                render 'new'
            end
        end
    end

    def edit
        @institution = Onepharma::Institution.where(CUSTOMER_ID: params[:id])[0]

        @address = Onepharma::Address.where(CUSTOMER_ID: params[:id]).by_active[0]
        @address_hmr = Onepharma::Address.where(CUSTOMER_ID: params[:id]).by_active[0]

        @institution_info = @institution.institution_info[0]
        if !@institution_info.present?
            @institution_info = @institution.institution_info.create!
        end

        #tickets - precisam de um main_object id, devido aos erros e para persistir a designação da variavel
        if current_user.can_do?("manage_tickets")
            @object_open_tickets = @institution.tickets.by_open.order(:created_at) || 0
        elsif current_user.can_do?("manage_only_team_tickets")
            @object_open_tickets = @institution.tickets.by_open.by_team(current_user.active_team).order(:created_at) || 0
        elsif current_user.can_do?("create_tickets")
            @object_open_tickets = @institution.tickets.by_open.where(user_id: current_user.id).order(:created_at) || 0
        end

        @ticket_object_id = @institution.CUSTOMER_ID
        @record_note = RecordNote.find_or_initialize_by(belong_to_object_id: @institution.CUSTOMER_ID)
        @new_department = Onepharma::Department.new
        @new_contact = Onepharma::Contact.new
        get_new_contact_url()

        #hmr_select_lists
        @geo_brick_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.geo3').pluck :DESCRIPTION, :CODE
        #@hmr_2015_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.geo6').pluck :DESCRIPTION, :CODE
        @m_brick_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.geo8').pluck :DESCRIPTION, :CODE
        @geobrick_sellout_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.geo9').pluck :DESCRIPTION, :CODE
        @geobrick_mb2020_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.geo10').pluck :DESCRIPTION, :CODE
        @geobrick_mb2023_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.MB2023').pluck :DESCRIPTION, :CODE

        add_breadcrumb I18n.t("breadcrumb_navigation.data_base_main_page"), db_main_page_path
        add_breadcrumb I18n.t("breadcrumb_navigation.edit_institution")
    end

    def update
        Onepharma::Institution.transaction do
            @institution= Onepharma::Institution.where(CUSTOMER_ID: params[:id])[0]
            @institution_info = @institution.institution_info[0]
            @address = Onepharma::Address.where(CUSTOMER_ID: params[:id]).by_active[0]

            #hmr_select_lists
            @geo_brick_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.geo3').pluck :DESCRIPTION, :CODE
            #@hmr_2015_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.geo6').pluck :DESCRIPTION, :CODE
            @m_brick_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.geo8').pluck :DESCRIPTION, :CODE
            @geobrick_sellout_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.geo9').pluck :DESCRIPTION, :CODE
            @geobrick_mb2020_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.geo10').pluck :DESCRIPTION, :CODE
            @geobrick_mb2023_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.MB2023').pluck :DESCRIPTION, :CODE

            if @institution.update(institution_params)
                @institution_info.update(institution_info_params)
                flash.now[:success] = I18n.t("alerts.records.institution_updated")
            else
                flash.now[:error] = I18n.t("alerts.records.erro_check_the_fields")
            end
        end
    end

    def update_hmr
        Onepharma::Address.transaction do
            @address_hmr = Onepharma::Address.where(CUSTOMER_ADDRESS_ID: params[:address_id]).by_active[0]

            #hmr_select_lists
            @geo_brick_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.geo3').pluck :DESCRIPTION, :CODE
            #@hmr_2015_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.geo6').pluck :DESCRIPTION, :CODE
            @m_brick_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.geo8').pluck :DESCRIPTION, :CODE
            @geobrick_sellout_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.geo9').pluck :DESCRIPTION, :CODE
            @geobrick_mb2020_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.geo10').pluck :DESCRIPTION, :CODE
            @geobrick_mb2023_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'geography.MB2023').pluck :DESCRIPTION, :CODE

            if @address_hmr.update(address_hmr_params)
                flash.now[:success] = I18n.t("alerts.records.address_hrm_updated")
            else
                flash.now[:error] = I18n.t("alerts.records.erro_check_the_fields")
            end
        end
    end

    def inst_dept_prof_affiliations_section_table
        @show_inactive = params[:show_inactive]
        @toggled = params[:toggled] != "true"

        @toggled= !@toggled

        Onepharma::Institution.transaction do
            @institution = Onepharma::Institution.where(CUSTOMER_ID: params[:institution_id])[0]

            @departments_professionals_affiliations = []
            ## lógica de Mostrar afiliações activas/inactivas
            ## mostra/esconde afiliações e profissionais activos/inactivos

            @institution_departments = @institution.departments.includes(professionals: :specialties)

            @institution_departments.eager_load(:prof_dept_affiliations,:dept_inst_affiliations).each do |dept|
                next if @show_inactive == "false" and dept.STATUS != 'ACTV'

                professionals_from_department = dept.professionals.index_by(&:CUSTOMER_ID)
                professional_specialties_list = {}
                professionals_from_department.each do |customer_id, prof|
                    professional_specialties_list[customer_id] = prof.specialties.pluck(:SPECIALTY)
                end

                professionals = []
                dept.prof_dept_affiliations.each do |affiliation|
                    #if affiliation.AFFILIATION_ID == '366348'
                    next if affiliation.FROM_CUSTOMER_ID == 0
                    next if @show_inactive == "false" and (affiliation.STATUS != 'ACTV' or professionals_from_department[affiliation.FROM_CUSTOMER_ID].STATUS != 'ACTV')

                    professionals << {
                        professional_id: affiliation.FROM_CUSTOMER_ID,
                        professional_name: professionals_from_department[affiliation.FROM_CUSTOMER_ID]&.FULL_NAME || "error",
                        professional_affiliation_status: affiliation.STATUS,
                        professional_affiliation_id: affiliation.AFFILIATION_ID ,
                        specialties: professional_specialties_list[affiliation.FROM_CUSTOMER_ID] || [""],
                        professional_number: professionals_from_department[affiliation.FROM_CUSTOMER_ID]&.EXTERNAL_ID_1
                    }
                end

                @departments_professionals_affiliations << {
                    department: dept,
                    department_affiliation_id: dept.dept_inst_affiliation.AFFILIATION_ID,
                    professionals: professionals.sort{|a,b| a[:professional_name] <=> b[:professional_name]}
                }
            end
        end

        #lista de especialidades
        @specialties_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'person.specialty_tmp', EXCLUDE: nil).order(DESCRIPTION: :asc).pluck :DESCRIPTION, :CODE
        #hash de especialidades
        @specialties_list_hash = @specialties_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }

    end

    def index_search
        if params[:search][:customer_id].blank?
            if params[:search][:full_name].blank? && params[:search][:line_address_1].blank? && params[:search][:cp].blank? && params[:search][:pa_city].blank?
                flash.now[:error] = I18n.t("alerts.empty_fields")
                return
            end
        elsif params[:search][:customer_id].blank? && params[:search][:full_name].length < 3
            flash.now[:error] = I18n.t("alerts.full_name_too_short")
            return
        #elsif !params[:search][:customer_id].blank? && !params[:search][:customer_id].to_s.match?(/\A\d+\z/)
        #    flash.now[:error] = I18n.t("alerts.must_be_number")
        #    return
        end

        @institutions_search_results = Onepharma::Institution.index_search_with(params[:search])

        searchCustomerStruct = Struct.new(:customer_id, :status, :full_name, :customer_type, :customer_sub_type, :line_address_1, :cp, :pa_city)

        aux = @institutions_search_results.eager_load(:addresses).each_with_object({}) do |institution, hash|
            #next if institution.addresses[0]&.STATUS != "ACTV"
            #next if !(institution.addresses[0]&.STATUS != "ACTV")
            hash[institution.CUSTOMER_ID] = searchCustomerStruct.new(institution.CUSTOMER_ID, institution.STATUS, institution.FULL_NAME, institution.CUSTOMER_TYPE, institution.CUSTOMER_SUB_TYPE || "")

            hash[institution.CUSTOMER_ID][:cp] = institution.get_full_cp
            hash[institution.CUSTOMER_ID][:line_address_1] = institution.addresses.by_active[0]&.LINE_ADDRESS_1
            hash[institution.CUSTOMER_ID][:pa_city] = institution.addresses.by_active[0]&.PA_CITY
        end

        @institutions_search_results = aux.values

        @institution_type_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'institution.type').pluck :DESCRIPTION, :CODE
        @institution_type_list_hash = @institution_type_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }

        @institution_sub_type_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'institution.sub_type').pluck :DESCRIPTION, :CODE
        @institution_sub_type_list_hash = @institution_sub_type_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }

    end

    def search_select2
        data = Onepharma::Institution.select("CUSTOMER_ID", "FULL_NAME", "op.CUSTOMER_ADDRESS.PA_CP4", "op.CUSTOMER_ADDRESS.PA_CP3", "op.CUSTOMER_ADDRESS.LINE_ADDRESS_1", "op.CUSTOMER_ADDRESS.PA_CITY").where(STATUS: ["ACTV", "DVLP"] )
                    .index_search_with({full_name: params[:search]}) #.where("op.CUSTOMER.FULL_NAME LIKE ?", "%#{params[:search]}%")
        data = data.map { |a| { id: a.CUSTOMER_ID, text: "#{a.FULL_NAME} | #{a.PA_CITY} | #{a.PA_CP4}-#{a.PA_CP3} | #{a.LINE_ADDRESS_1} "} }

        render json: { results: data }
    end

    private
    def set_tab
        @tab = :institutions
    end

    def institution_params
        params.require(:onepharma_institution).permit(:FULL_NAME, :CUSTOMER_TYPE, :CUSTOMER_SUB_TYPE, :STATUS_CHANGE_REASON, addresses_attributes: [:id, :CUSTOMER_ADDRESS_ID, :STATUS, :LINE_ADDRESS_1, :PA_CP3, :PA_CP4, :PA_CITY, :CITY_2_ID, :CITY_3_ID, :GEOGRAPHY_CODE_3, :GEOGRAPHY_CODE_6, :GEOGRAPHY_CODE_8, :GEOGRAPHY_CODE_9, :GEOGRAPHY_CODE_10])
    end

    def institution_info_params
        params.require(:onepharma_institution)
            .require(:onepharma_institution_info)
            .permit(:VAT_NUMBER, :AMF_NUMBER)
    end

    def address_params
        params.require(:onepharma_institution)
            .require(:addresses_attributes)
            .permit(:LINE_ADDRESS_1, :PA_CP3, :PA_CP4, :PA_CITY, :CITY_2_ID, :CITY_3_ID, :GEOGRAPHY_CODE_3, :GEOGRAPHY_CODE_6, :GEOGRAPHY_CODE_8, :GEOGRAPHY_CODE_9, :GEOGRAPHY_CODE_10, :GEOGRAPHY_MB2023)
    end

    def address_hmr_params
        params.require(:onepharma_address).permit(:id, :GEOGRAPHY_CODE_3, :GEOGRAPHY_CODE_6, :GEOGRAPHY_CODE_8, :GEOGRAPHY_CODE_9,:GEOGRAPHY_CODE_10, :GEOGRAPHY_MB2023)
    end

    def get_new_contact_url
        # url para form institutions/contact
        @institution= Onepharma::Institution.where(CUSTOMER_ID: params[:id])[0]
        @new_contact_url = institution_contacts_path(@institution.CUSTOMER_ID)
    end

    def get_lists
        #lista de tipos
        @institution_type_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'institution.type').order(DESCRIPTION: :asc).pluck :DESCRIPTION, :CODE
        @institution_type_list_hash = @institution_type_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }

        @institution_sub_type_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'institution.sub_type').order(DESCRIPTION: :asc).pluck :DESCRIPTION, :CODE
        @institution_sub_type_list_hash = @institution_sub_type_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }

        #lista de subtipos
        @department_type_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'department.type', EXCLUDE: nil).order(DESCRIPTION: :asc).pluck :DESCRIPTION, :CODE
        @department_sub_type_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'department.sub_type', EXCLUDE: nil).order(DESCRIPTION: :asc).pluck :DESCRIPTION, :CODE

        #hash de tipos e subtipos
        @department_type_hash = @department_type_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }
        @department_sub_type_hash = @department_sub_type_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }

        #lista de tipos validação
        @validation_type_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'validation.change_reason').order(DESCRIPTION: :asc).pluck :DESCRIPTION, :CODE

        @institution_PA_CITY_list_for_select = Onepharma::Address.by_active.distinct.pluck :PA_CITY
        @institution_list_for_select = Onepharma::Institution.by_active.pluck(:FULL_NAME, :CUSTOMER_ID)

        #histórico
        @log_record_activity_list = LogRecord.get_by_object_id(params[:id])
        get_user_email_list

        #lista de conselhos
        @institution_city_2_id_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'address.city2').order(DESCRIPTION: :asc).pluck(:DESCRIPTION, :CODE).map { |desc, code| [desc, code.to_s] }
        @institution_city_2_id_list_hash = @institution_city_2_id_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }

        #lista de distritos
        @institution_city_3_id_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'address.city3').order(DESCRIPTION: :asc).pluck :DESCRIPTION, :CODE
        @institution_city_3_id_list_hash = @institution_city_3_id_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }
    end

    def get_user_email_list
        @users_email = {}
        User.all.each do |user|
            @users_email[user.id] = user.name
        end
    end
end
