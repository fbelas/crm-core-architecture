import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

export default class extends Controller {
    static values = {
        tags: Boolean,
        placeholder: String,
        minimuminputlength: Number,
        matcher: String,
        onselectcallurl: String,
        alertonselect: Array,
        searchurl: String
    }

    connect() {
        let isMultiple = this.element.hasAttribute("multiple");

        let selectOptions = {
            placeholder: this.placeholderValue,
            tags: this.tagsValue,
            minimumInputLength: this.minimuminputlengthValue,
            allowClear: true,
            //closeOnSelect: !isMultiple,

            //para alterar o style consoante o que for
            // passado na collection, ver o exemplo no controller das extractions @main_object_fields_list
            templateResult: function(option) {
                if (!option.id) return option.text;

                let $option = $(option.element);
                let size = $option.data('size');
                let style = $option.data('style');
                let icon = $option.data('icon');


                let $styledOption = $("<span></span>").text(option.text);
                if (icon) { $styledOption.append('  <i class="' +icon + '"></i> '); }
                if (size) { $styledOption.css('font-size', size); }
                if (style) { $styledOption.attr('style', style); }

                return $styledOption;
            }
        };

        if(this.matcherValue == "match_by_words_beginning"){
            selectOptions["matcher"] = this._match_by_words_beginning;
        };

        //search a list of values insid the seelect2
        if(this.searchurlValue){
            selectOptions = {...selectOptions, ...{
                ajax: {
                  url: this.searchurlValue,
                  dataType: 'json',
                  delay: 250,
                  data: function (params) {
                    var query = {
                        search: params.term
                    }
                    return query;
                }
                }
            }}
        }

        //if (!($(this.element).siblings("select2-"+this.element.id+"-container"))){
            $(this.element).select2(selectOptions);
        //}

        // passar o url
        if(this.onselectcallurlValue){//on_select_call_url
            $(this.element).on('select2:select', (e) => {
                post(this.onselectcallurlValue, {body: { selected_value: e.params.data.id}, responseKind: "turbo-stream"})
            });
        }

        // alertonselect - sempre que necessário passar alertas com base na selecção
        //basta passar uma lista com os valores
        //e a mensagem de alerta caso esses valores não sejam selecionados
        if(this.alertonselectValue.length > 0){
            $(this.element).on('select2:select', (e) => {
                const selectedValue = e.params.data.id;
                const allowedValues = this.alertonselectValue[0].map(String);

                if (!allowedValues.includes(selectedValue)) {
                    window.alert(this.alertonselectValue[1]);
                }
            });
        }
    }


    _match_by_words_beginning(params, data) {
        // If there are no search terms, return all of the data
        if ($.trim(params.term) === '') {
            return data;
        }

        // Do not display the item if there is no 'text' property
        if (typeof data.text === 'undefined') {
            return null;
        }

        // `params.term` should be the term that is used for searching
        // `data.text` is the text that is displayed for the data object

        let regex_str = params.term.replace(/\s+/g, '.*')
        const regex = new RegExp(regex_str, 'gi')

        if (regex.test(data.text)) {
            return data
            /*var modifiedData = $.extend({}, data, true);
            modifiedData.text += ' (matched)';

            // You can return modified objects from here
            // This includes matching the `children` how you want in nested data sets
            return modifiedData;*/
        }

        // Return `null` if the term should not be displayed
        return null;
    }

}
