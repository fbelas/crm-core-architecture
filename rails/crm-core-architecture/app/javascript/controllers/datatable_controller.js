import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        target_table_id: String,
        search_translation: String,
        orderByColumn: Number
    }
    connect() {
        let button_group = []
        let element = this.element
        this.default_filter = {}
        if(element.tagName == 'TABLE'){
            this.html_table = element
        } else {
            this.html_table = element.querySelector('table')
        }

        if (!$.fn.DataTable.isDataTable(this.html_table)) {
            let data_table = $(this.html_table)

            this.downloadbutton(data_table, button_group)
            this.proxydownloadbutton(button_group)
            this.quicksearchbutton(data_table, button_group)

            // Adiciona o objecto com o buttons *********************************
            this.datatable = $(this.html_table).DataTable({
                layout: {
                    topLeft: {
                        buttons: button_group,
                    }
                },
                language: {
                    search: this.searchTranslationValue
                 },
                searchHighlight: true,
                order: this.hasOrderByColumnValue? [[this.orderByColumnValue, 'asc']]: []
            });
            this.element.addEventListener('ReloadNewData', this.reloadNewData.bind(this));
            if (this.default_filter && this.default_filter.columns !== undefined) {
                const columnIndex = parseInt(this.default_filter.columns, 10);
                const value = this.default_filter.value;

                this.datatable.column(columnIndex).search(value, { exact: true }).draw();

                $(this.datatable.table().body()).find('.column_highlight').removeClass('column_highlight');
            }
        }
        //if (!($(this.element).siblings("select2-"+this.element.id+"-container"))){
        //}
    };

    reloadNewData(e) {
        this.datatable.clear();
        this.datatable.rows.add( e.detail )
        this.datatable.draw();

        $(window).trigger('resize');
    }

    proxydownload(event) {
        const hiddenTable = document.getElementById(this.element.dataset.target_table_id);
        const datatable = $(hiddenTable).DataTable();
        datatable.buttons('.buttons-excel').trigger();
    }

    quicksearchbutton(data_table, button_group){
        //Quick Search *********************************
        //Para fazer a pesquisa rápida na tabela basta preencher este campos na dt
        //quick_search_field="" quick_search_value=""
        //$(this.datatable.table().body()).find('.column_highlight').removeClass('column_highlight');='{"field_1":"1", "value_1":"Duplicado", "field_2":"1", "value_2":"Inactivo"}'
        //if (!(data_table.attr("quick_search_value") == "")){

        if (data_table.data('quick-search') != undefined){
            let fields_and_filter = data_table.data('quick-search')
            let no_more_attributes = false
            let count = 1
            //verifica se a tabela tem quick-search attributes

            while (no_more_attributes == false){
                let filter_column = fields_and_filter["field_"+ count]
                let filter_value = fields_and_filter["value_"+ count]
                let filter_button_text = "<span class='btn-label'><i class='fa-solid fa-eye'></i></span>"+fields_and_filter["button_text_"+ count]
                let filter_default = fields_and_filter["filter_default_"+ count]

                //enquanto encontrar o objecto cujo o numero corresponde ao contador
                //vai agarrar nesse sdados e fazer push do botao para a lista de botoes
                if (filter_column){
                    count ++

                    button_group.push(
                        {
                            text: filter_button_text,
                            action: function (e, dt, node, config) {
                            if (filter_value){
                                if (data_table.DataTable().column(filter_column).search() == "") {
                                    data_table.DataTable().column(filter_column).search(filter_value, {
                                        exact: true
                                    } ).draw();
                                    $(node).removeClass("btn-grey").addClass("btn-light_dark_blue");
                                    $(data_table.DataTable().table().body()).find('.column_highlight').removeClass('column_highlight');

                                }else{
                                    data_table.DataTable().column(filter_column).search("").draw();
                                    $(node).removeClass("btn-light_dark_blue").addClass("btn-grey");
                                }}
                            },
                            className: function() {
                                return (filter_default === 'true' && filter_value) ? 'btn-light_dark_blue waves-effect waves-light' : 'btn-grey';
                            }
                        },
                        {
                            extend: 'spacer',
                            style: 'bar'
                        }
                    )
                    if (filter_default==='true' && filter_value) {
                        this.default_filter = {columns: filter_column, value: filter_value}
                    }
                }else{
                    no_more_attributes = true

                }
            }
        }
    }

    downloadbutton(data_table, button_group){
        //Dowload button *********************************
        if (data_table.attr("downloadable") == "true") {
            button_group.push(
                {
                    extend: 'excel',
                    text: 'Download .xls',
                    className: "btn-dark_green"
                },
                {
                    extend: 'spacer',
                    style: 'bar'
                }
            )
        }
    }

    proxydownloadbutton(button_group){
        //Proxy Download *********************************
        //No caso da datatable das isntituições exste uma tabela hidden
        //ao preencher com o id da tabela hidden o botão de download vai buscar ai a data
        //data-datatable-target_table_id-value="hidden_export_inst_dept_prof_affiliations_section_table"
        if (this.targetTableIdValue) {
            button_group.push(
                {
                    extend: '',
                    text: 'Download .xls',
                    className: "btn btn-dark_green waves-effect waves-light",
                    attr: {
                        id: 'download_proxy',
                        'data-action': 'datatable#proxydownload',
                        'data-target_table_id': 'hidden_export_table',
                        'data-controller':"datatable"
                    }
                },
                {
                    extend: 'spacer',
                    style: 'bar'
                }
            )

        }
    }



}
