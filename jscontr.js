/**
 * The Base control that all other controls inherrit from
 */

var BaseControl = function(options) {

};

BaseControl.prototype.getValue = function() {
    return this.element.val();
};

BaseControl.prototype.setValue = function(value) {
    this.element.val(value);
};

BaseControl.prototype.reset = function() {
    this.element.val('');
};

BaseControl.prototype.disable = function() {
    this.element.attr('disabled', true);
};

BaseControl.prototype.enable = function() {
    this.element.attr('disabled', false);
};

BaseControl.prototype.getElements = function() {
    if (this.element) {
        return [this.element];
    } else {
        return [];
    }
};

BaseControl.prototype.showElements = function() {
    this.element.show();
};

BaseControl.prototype.hideElements = function() {
    this.element.hide();
};

BaseControl.prototype.removeElements = function() {
    this.element.remove();
};

BaseControl.prototype.addElementsTo = function(element) {
    element.append(this.element);
};

var MultiElementControl = function(options) {}

MultiElementControl.prototype = Object.create(BaseControl.prototype);
MultiElementControl.prototype.constructor = MultiElementControl;

MultiElementControl.prototype.disable = function() {
    this.is_enabled = false;
    for (var i = 0; i < this.elements.length; i++) {
        this.elements[i].attr('disabled', true);
    }
};

MultiElementControl.prototype.enable = function() {
    this.is_enabled = true;
    for (var i = 0; i < this.elements.length; i++) {
        this.elements[i].attr('disabled', false);
    }
};

MultiElementControl.prototype.getElements = function() {
    if (this.elements) {
        return this.elements;
    } else {
        return [];
    }
};

MultiElementControl.prototype.showElements = function() {
    for (var i = 0; i < this.elements.length; i++) {
        this.elements[i].show();
    }
};

MultiElementControl.prototype.hideElements = function() {
    for (var i = 0; i < this.elements.length; i++) {
        this.elements[i].hide();
    }
};

MultiElementControl.prototype.removeElements = function() {
    for (var i = 0; i < this.elements.length; i++) {
        this.elements[i].remove();
    }
};

MultiElementControl.prototype.addElementsTo = function(element) {
    for (var i = 0; i < this.elements.length; i++) {
        element.append(this.elements[i]);
    }
};

var ControlConstructors = {
    many_to_many: function(options) {
        var self = this;
        MultiElementControl.call(this, options);
        this.out_select = $('<select class="out-elements" multiple="multiple"></select>');
        if (typeof(options) == "undefined") {
            options = [];
        }
        for (var i = 0; i < options.length; i++) {
            this.out_select.append('<option title="' + options[i].name + '" value="' + options[i].internal_name + '">' + options[i].name + '</option>');
        }
        this.in_select = $('<select class="in-elements" multiple="multiple"></select>');
        this.bump_up_button = $('<button class="up-down-btn">&#8593;</button>');
        this.bump_up_button.click(function() {
            self.bumpSelectedUp();
        });
        this.bump_down_button = $('<button class="up-down-btn">&#8595;</button>');
        this.bump_down_button.click(function() {
            self.bumpSelectedDown();
        });
        var up_down_container = $('<div class="up-down-btn-container"></div>');
        up_down_container.append(this.bump_up_button);
        up_down_container.append(this.bump_down_button);
        this.add_button = $('<button class="many-to-many-add">Add</button>');
        this.add_button.click(function() {
            self.moveSelectedElements(self.out_select, self.in_select);
        });
        this.out_select.dblclick(function() {
            self.moveSelectedElements(self.out_select, self.in_select);
        });
        this.remove_button = $('<button class="many-to-many-remove">Remove</button>');
        this.remove_button.click(function() {
            self.moveSelectedElements(self.in_select, self.out_select);
        });
        this.in_select.dblclick(function() {
            self.moveSelectedElements(self.in_select, self.out_select);
        });
        this.elements = [
            this.out_select,
            this.in_select,
            up_down_container,
            this.add_button,
            this.remove_button
        ];
    },
    many_to_many_with_context: function(options) {
        ControlConstructors.many_to_many.call(this, options.options);
        this.context_container = $('#' + options.context_container_id);
        this.context_fields = options.context_fields;
        var self = this;
        // The following add methods that are called AFTER the
        // corresponding events on the parent class
        // (many_to_many)
        this.in_select.change(function() {
            self.updateVisibleContextControls();
        });
        this.bump_up_button.click(function() {
            self.recreateContextControls();
            self.updateVisibleContextControls();
        });
        this.bump_down_button.click(function() {
            self.recreateContextControls();
            self.updateVisibleContextControls();
        });
        this.add_button.click(function() {
            self.recreateContextControls();
            self.updateVisibleContextControls();
        });
        this.out_select.dblclick(function() {
            self.recreateContextControls();
            self.updateVisibleContextControls();
        });
        this.remove_button.click(function() {
            self.recreateContextControls();
            self.updateVisibleContextControls();
        });
        this.in_select.dblclick(function() {
            self.recreateContextControls();
            self.updateVisibleContextControls();
        });
    },
    select: function(options) {
        BaseControl.call(this, options);
        if (typeof(options) === 'undefined') {
            options = [];
        }
        this.id_name = 'id';
        this.label_name = 'label';
        this.element = $('<select><option value=""></option></select>');
        for (var i = 0; i < options.length; i++) {
            var id = options[i].id || options[i].internal_name;
            var label = options[i].label || options[i].name;
            this.element.append('<option value="' + id + '">' + label + '</option>');
        }
        this.on_change = function(choice) {};
        var self = this;
        this.element.change(function() {
            self.on_change(self.getValue());
        });
    },
    input: function(options) {
        BaseControl.call(this, options);
        this.element = $('<input type="text">');
    },
    multiline: function(options) {
        BaseControl.call(this, options);
        this.element = $('<textarea></textarea>');
    },
    row: function(options) {
        MultiElementControl.call(this, options);
        this.elements = []
        this.fields = options;
        this.field_elements = [];
        for (var i=0; i<this.fields.length; i++) {
            this.elements.push($('<div class="table-control-field-label">' + this.fields[i].label + '</div>'));
            var new_field = new ControlConstructors[this.fields[i].type](this.fields[i].options);
            this.field_elements.push(new_field);
            var new_elements = new_field.getElements();
            this.elements.push($('<div class="table-control-field"></div>').append(new_elements[0]));
            for (var j = 1; j < new_elements.length; j++) {
                this.elements.push(new_elements[j]);
            }
        }
    },
    branch: function(options) {
        MultiElementControl.call(this, options);
        var self = this;
        this.fields = {"":[]};
        this.branch_containers = [];
        this.branch_selector = $('<select><option value=""></option></select>');
        this.elements = [this.branch_selector];
        for (var i=0; i<options.length; i++) {
            this.branch_selector.append('<option value="' + options[i].name + '">' + options[i].label + '</option>');
            var branch_fields_container = $('<span></span>');
            branch_fields_container.hide();
            this.elements.push(branch_fields_container);
            var branch_fields = [];
            if (options[i].hasOwnProperty('children')) {
                for (var child_number = 0; child_number < options[i].children.length; child_number++) {
                    var new_control = new ControlConstructors[options[i].children[child_number].type](options[i].children[child_number].options);
                    branch_fields.push({
                        name: options[i].children[child_number].name,
                        control: new_control
                    });
                    branch_fields_container.append($('<div class="table-control-field-label">' + options[i].children[child_number].label + '</div>'));
                    var new_control_elements = new_control.getElements();
                    branch_fields_container.append($('<div class="table-control-field"></div>').append(new_control_elements[0]));
                    for (var sub_element_number = 1; sub_element_number < new_control_elements.length; sub_element_number++) {
                        branch_fields_container.append(new_control_elements[sub_element_number]);
                    }
                }
            }
            this.fields[options[i].name] = branch_fields;
            this.branch_containers.push({
                name: options[i].name,
                element: branch_fields_container
            });
        }
        this.branch_selector.change(function() {
            for (var i = 0; i < self.branch_containers.length; i++) {
                if (self.branch_containers[i].name == self.branch_selector.val()) {
                    self.branch_containers[i].element.show();
                } else {
                    self.branch_containers[i].element.hide();
                }
            }
        });
    },
    search_select: function(options) {
        BaseControl.call(this, options);
        var self = this;
        this.element = $('<span class="search-selector"></span>');
        this.search_box = $('<input class="selector-search-box" type="text">');
        this.search_results = $('<div class="search-select-results"></div>');
        this.element.append(this.search_box);
        this.element.append(this.search_results);
        this.search_url = options.search_url;
        if (options.identifier_name) {
            this.identifier_name = options.identifier_name;
        } else {
            this.identifier_name = "internal_name";
        }
        if (options.on_select) {
            this.onSelect = options.on_select;
        }
        this.search_box.keyup(function() {
            var search_string = self.search_box.val();
            self.selected = "";
            if (search_string == '') {
                self.search_results.hide();
                self.search_results.empty();
                return;
            }
            window.setTimeout(function() {
                /* If we send an ajax request every time the user hits
                 * a key, (including backspace) we run the risk of
                 * overloading the server. Our solution is to wait a
                 * fraction of second, and if the search box hasn't
                 * changed then we send the ajax request.
                 */
                if (self.search_box.val() == search_string) {
                    ajaxPost(
                        self.search_url,
                        {
                            name: search_string,
                            max_count: 100
                        },
                        function() {},
                        function(data) {
                            self.search_results.empty();
                            for (var i=0; i<data.results.length; i++) {
                                var element_id = data.results[i][self.identifier_name];
                                var element_name = data.results[i].name;
                                var search_result = $('<div class="search-select-result" data-element-id="' + element_id + '">' + element_name + '</div>');
                                search_result.click(function() {
                                    // Inside the event handler, "this"
                                    // is the html element that was
                                    // clicked
                                    self.onSelect($(this).attr('data-element-id'), $(this).text());
                                    self.search_results.hide();
                                    self.search_results.empty();
                                    self.search_box.focus();
                                });
                                self.search_results.append(search_result);
                            }
                            self.search_results.show();
                        }
                    );
                }
            }, 300);
        });
    },
    benchmark_selector: function(options) {
        if (!options) {
            options = {};
        }
        options.identifier_name = 'instrument_id';
        options.search_url = '/ratings/search_biograph_benchmarks';
        ControlConstructors.search_select.call(this, options);
    },
    orderable_list: function(options) {
        var self = this;
        if (!options) {
            options = {};
        }
        BaseControl.call(this, options);
        this.element = $('<div class="orderable-list"></div>');
        var select_container = $('<div></div>');
        this.element.append(select_container);
        this.results = $('<select multiple="multiple"></select>');
        select_container.append(this.results);
        var bump_up_button = $('<button class="up-down-btn">&#8593;</button>');
        bump_up_button.click(function() {
            self.bumpSelectedUp();
        });
        var bump_down_button = $('<button class="up-down-btn">&#8595;</button>');
        bump_down_button.click(function() {
            self.bumpSelectedDown();
        });
        var up_down_container = $('<div class="up-down-btn-container"></div>');
        up_down_container.append(bump_up_button);
        up_down_container.append(bump_down_button);
        select_container.append(up_down_container);
        var remove_button = $('<button class="many-to-many-btn">Remove</button>');
        remove_button.click(function() {
            self.results.find('option:selected').remove();
            self.onChange();
        });
        this.element.append(remove_button);
        var clear_out_button = $('<button class="many-to-many-btn">Clear</button>');
        clear_out_button.click(function() {
            self.results.empty();
            self.onChange();
        });
        this.element.append(clear_out_button);
    },
    multi_search_select: function(options) {
        BaseControl.call(this, options);
        var self = this;
        this.selected = [];
        if (options.identifier_name) {
            this.identifier_name = options.identifier_name;
        } else {
            this.identifier_name = "internal_name";
        }
        this.element = $('<div class="multi-search-select"></div>');
        options.on_select = function (selected_id, selected_name) {
            var new_element = {
                name: selected_name
            };
            new_element[self.identifier_name] = selected_id;
            self.selected.push(new_element);
            self.results.add(selected_id, selected_name);
            self.search_box.reset();
        };
        this.search_box = new ControlConstructors.search_select(options);
        this.search_box.addElementsTo(this.element);
        this.results = new ControlConstructors.orderable_list();
        this.results.addElementsTo(this.element);
    },
    multi_benchmark_select: function(options) {
        if (!options) {
            options = {};
        }
        options.identifier_name = 'instrument_id';
        options.search_url = '/ratings/search_biograph_benchmarks';
        ControlConstructors.multi_search_select.call(this, options);
    },
    TableControl: function(fields, row_constructor) {
        MultiElementControl.call(this);
        this.is_enabled = true;
        var self = this;
        this.fields = fields;
        this.add_row_button = $('<button>Add</button>');
        this.add_row_button.click(function() {
            self.addRow();
        });
        this.container_element = $('<div class="table-control-container"></div>');
        this.elements = [
            this.add_row_button,
            this.container_element
        ];
        this.field_rows = [];
        this.next_row_id = 0;
        this.row_constructor = row_constructor;
    },
    PerformanceObjectiveControl: function() {
        ControlConstructors.TableControl.call(this, [
            {
                name: "is_before_fees",
                label: "Is this objective before or after fees?",
                type: "select",
                options: [
                    {id: "before", label: "Before fees"},
                    {id: "after", label: "After fees"}
                ]
            },
            {
                name: "is_secondary_objective",
                label: "Is this a catch all secondary objective?",
                type: "branch",
                options: [
                    {
                        name:"yes",
                        label:"Yes",
                        children: [
                            {
                                name: "description",
                                label: "Describe the objective:",
                                type: "multiline",
                            },
                            {
                                name: "was_met",
                                label: "Did the product meet the objective?",
                                type: "select",
                                options: [
                                    {id: "yes",label:"Yes"},
                                    {id: "not_quite",label:"Slightly below"},
                                    {id: "no",label:"No"}
                                ]
                            }
                        ]
                    },
                    {
                        name:"no",
                        label:"No",
                        children: [
                            {
                                name: "which_years",
                                label: "Does it apply in up or down markets?",
                                type: "select",
                                options: [
                                    {id:"up",label:"in up markets."},
                                    {id:"down",label:"in down markets."},
                                    {id:"all",label:"in all markets"}
                                ]
                            },
                            {
                                name: "return_type",
                                label: "Is it an income or a total return objective?",
                                type: "branch",
                                options: [
                                    {
                                        name: "income",
                                        label: "Income",
                                        children: [
                                            {
                                                name: "total_return_benchmark",
                                                label: "Total return benchmark",
                                                type: "benchmark_selector"
                                            },
                                            {
                                                name: "capital_return_benchmark",
                                                label: "Capital return benchmark",
                                                type: "benchmark_selector"
                                            }
                                        ]
                                    },
                                    {
                                        name: "return",
                                        label: "Total Return",
                                        children: [
                                            {
                                                name: "benchmark",
                                                label: "Benchmark (leave blank if it's an absolute return objective)",
                                                type: "benchmark_selector"
                                            }
                                        ]
                                    }
                                ]
                            },
                            {
                                name: "out_performance_or_range",
                                label: "Is there a single return/yield target, or a range?",
                                type: "branch",
                                options: [
                                    {
                                        name: "min",
                                        label: "Single target",
                                        children: [
                                            {
                                                name: "min",
                                                label: "Plus target (%pa, e.g. \"3\" for 3%pa)",
                                                type: "input"
                                            }
                                        ]
                                    },
                                    {
                                        name: "range",
                                        label: "A range",
                                        children: [
                                            {
                                                name: "min",
                                                label: "Minimum excess (%pa, e.g. \"3\" for 3%pa):",
                                                type: "input"
                                            },
                                            {
                                                name: "max",
                                                label: "Maximum:",
                                                type: "input"
                                            }
                                        ]
                                    }
                                ]
                            },
                            {
                                name: "period_type",
                                label: "When do they aim to meet the objective?",
                                type: "branch",
                                options: [
                                    {
                                        name: "time_period",
                                        label: "Over a rolling X month/year period",
                                        children: [
                                            {
                                                name: "period",
                                                label: "Where X is?",
                                                type: "input"
                                            },
                                            {
                                                name: "period_type",
                                                label: "Months or years?",
                                                type: "select",
                                                options: [
                                                    {id:"months",label:"Months"},
                                                    {id:"years",label:"Years"}
                                                ]
                                            }
                                        ]
                                    },
                                    {
                                        name: "x_y",
                                        label: "X out of rolling Y periods",
                                        children: [
                                            {
                                                name: "hits",
                                                label: "Where X is?",
                                                type: "input"
                                            },
                                            {
                                                name: "total_periods",
                                                label: "and Y is?",
                                                type: "input"
                                            },
                                            {
                                                name: "period_type",
                                                label: "Months or years?",
                                                type: "select",
                                                options: [
                                                    {id:"months",label:"Months"},
                                                    {id:"years",label:"Years"}
                                                ]
                                            }
                                        ]
                                    }
                                ]
                            }
                        ]
                    }
                ]
            }
        ], ControlConstructors.row);
    },
    RiskObjectiveControl: function() {
        ControlConstructors.TableControl.call(this, [
            {
                name: "is_secondary_objective",
                label: "Is this a catch all secondary objective?",
                type: "branch",
                options: [
                    {
                        name: "yes",
                        label: "Yes",
                        children: [
                            {
                                name: "description",
                                label: "Describe the objective:",
                                type: "multiline",
                            },
                            {
                                name: "was_met",
                                label: "Did the product meet the objective?",
                                type: "select",
                                options: [
                                    {id: "yes",label:"Yes"},
                                    {id: "not_quite",label:"Slightly below"},
                                    {id: "no",label:"No"}
                                ]
                            }
                        ]
                    },
                    {
                        name: "no",
                        label: "No",
                        children: [
                            {
                                name: "risk_target_type",
                                label: "Is this an absolute, tracking error, or relative risk target?",
                                type: "branch",
                                options: [
                                    {
                                        name: "absolute",
                                        label: "An absolute risk objective",
                                        children: [
                                            {
                                                name: "range_or_max",
                                                label: "Is there a range of acceptable risk levels, or just a maximum?",
                                                type: "branch",
                                                options: [
                                                    {
                                                        name: "range",
                                                        label: "a range",
                                                        children: [
                                                            {
                                                                name: "min",
                                                                label: "Minimum (annualised) standard deviation of monthly returns (%pa, for example \"3\" for 3%pa):",
                                                                type: "input"
                                                            },
                                                            {
                                                                name: "max",
                                                                label: "Maximum (annualised) standard deviation of monthly returns:",
                                                                type: "input"
                                                            }
                                                        ]
                                                    },
                                                    {
                                                        name: "max",
                                                        label: "a maximum",
                                                        children: [
                                                            {
                                                                name: "max",
                                                                label: "Maximum (annualised) standard deviation of monthly returns (%pa, for example \"3\" for 3%pa):",
                                                                type: "input"
                                                            }
                                                        ]
                                                    }
                                                ]
                                            }
                                        ]
                                    },
                                    {
                                        name: "tracking error",
                                        label: "A tracking error target",
                                        children: [
                                            {
                                                name: "benchmark",
                                                label: "What is the benchmark to use for tracking error?",
                                                type: "benchmark_selector"
                                            },
                                            {
                                                name: "range_or_max",
                                                label: "Is there a range of acceptable tracking errors, or just a maximum?",
                                                type: "branch",
                                                options: [
                                                    {
                                                        name: "range",
                                                        label: "a range",
                                                        children: [
                                                            {
                                                                name: "min",
                                                                label: "Minimum tracking error(%pa, for example \"3\" for 3%pa):",
                                                                type: "input"
                                                            },
                                                            {
                                                                name: "max",
                                                                label: "Maximum tracking error:",
                                                                type: "input"
                                                            }
                                                        ]
                                                    },
                                                    {
                                                        name: "max",
                                                        label: "a maximum",
                                                        children: [
                                                            {
                                                                name: "max",
                                                                label: "Maximum (annualised) standard deviation of monthly returns (%pa, for example \"3\" for 3%pa):",
                                                                type: "input"
                                                            }
                                                        ]
                                                    }
                                                ]
                                            }
                                        ]
                                    },
                                    {
                                        name: "relative",
                                        label: "A relative risk target",
                                        children: [
                                            {
                                                name: "benchmark",
                                                label: "What is the benchmark to use for relative risk?",
                                                type: "benchmark_selector"
                                            },
                                            {
                                                name: "percentage",
                                                label: "The (annualised) standard deviation of monthly returns should be less than X% of the standard deviation of monthly returns of the benchmark. Where X is (%, for example \"80\" for 80%):",
                                                type: "input"
                                            }
                                        ]
                                    }
                                ]
                            },
                            {
                                name: "period_type",
                                label: "When do they aim to meet the objective?",
                                type: "branch",
                                options: [
                                    {
                                        name: "time_period",
                                        label: "Over a rolling X month/year period",
                                        children: [
                                            {
                                                name: "period",
                                                label: "Where X is?",
                                                type: "input"
                                            },
                                            {
                                                name: "period_type",
                                                label: "Months or years?",
                                                type: "select",
                                                options: [
                                                    {id:"months",label:"Months"},
                                                    {id:"years",label:"Years"}
                                                ]
                                            }
                                        ]
                                    },
                                    {
                                        name: "x_y",
                                        label: "X out of rolling Y years",
                                        children: [
                                            {
                                                name: "hits",
                                                label: "Where X is?",
                                                type: "input"
                                            },
                                            {
                                                name: "total_periods",
                                                label: "and Y is?",
                                                type: "input"
                                            }
                                        ]
                                    }
                                ]
                            }
                        ]
                    }
                ]
            }
        ], ControlConstructors.row);
    },
    DisplayTable: function(columns, default_value, name_column_label) {
        BaseControl.call(this, {});
        var self = this;
        this.element = $('<table></table>');
        if (name_column_label) {
            // The name column can be set with the name_column_label
            // parameter. This is the heading of the column above the
            // first column.
            var name_column_heading = $('<th>' + name_column_label + '</th>');
            name_column_heading.click(function() {
                self.orderRowsBy('', true);
            });
            var table_header = $('<tr></tr>');
            table_header.append(name_column_heading);
        } else {
            // The default however is to leave this cell blank.
            var table_header = $('<tr><td></td></tr>');
        }
        this.element.append($('<thead></thead>').append(table_header));
        this.table_body = $('<tbody></tbody>');
        this.element.append(this.table_body);
        this.column_ids = [];
        this.column_names = [];
        this.cells = {};
        for (var i = 0; i < columns.length; i++) {
            this.column_ids.push(columns[i].internal_name);
            this.column_names.push(columns[i].name);
            var new_header_cell = $('<th data-internalname="' + columns[i].internal_name + '">' + columns[i].name + '</th>');
            var column_id = columns[i].internal_name;
            new_header_cell.click(function(event) {
                self.orderRowsBy($(this).attr('data-internalname'));
            });
            table_header.append(new_header_cell);
        }
        this.default_value = default_value;
        this.rows = {};
        this.row_names = {};
        this.current_ranking_column = null;
        this.current_ranking_direction = 1;
    },
    VariableColumnDisplayTable: function(rows, default_value) {
        BaseControl.call(this, {});
        this.default_value = default_value;
        this.element = $('<table></table>');
        this.cells = {};
        this.rows = {};
        this.row_ids = [];
        this.header_row = $('<tr><td></td></tr>');
        this.element.append(this.header_row);
        for (var i = 0; i < rows.length; i++) {
            var new_row = $('<tr><th>' + rows[i].name + '</th></tr>');
            this.rows[rows[i].id] = new_row;
            this.element.append(new_row);
            this.row_ids.push(rows[i].id);
        }
    },
    ScreenPager: function(container) {
        BaseControl.call(this, {});
        this.element = container;
        this.screens = {};
        var screens = container.children();
        this.screen_ids = [];
        for (var i = 0; i < screens.length; i++) {
            var screen = $(screens[i]);
            var screen_id = screen.attr('id');
            this.screen_ids.push(screen_id);
            this.screens[screen_id] = screen;
            screen.hide();
        }
        container.show();
        this.screens[this.screen_ids[0]].show();
    },
    DynamicList: function() {
        BaseControl.call(this, {});
        this.element = $('<ul></ul>');
        this.list_items = {};
    },
    IndentedList: function(indentation_amount) {
        ControlConstructors.DynamicList.call(this, {});
        this.indentation_amount = indentation_amount;
    },
    IndentedInput: function(original_width, indent_width, enter_callback) {
        MultiElementControl.call(this, {});
        this.indent_width = indent_width;
        this.original_width = original_width;
        var self = this;
        this.enter_callback = enter_callback;
        this.indent = 0;
        this.input_element = $('<input></input>');
        this.input_element.css('width', original_width + "px");
        var ok_button = $('<button style="display: inline-block">OK</button>');
        ok_button.click(function() {
            self.enter_callback(self.input_element.val(), self.indent);
            self.input_element.val("");
            self.input_element.focus();
        });
        this.elements = [
            this.input_element,
            ok_button
        ];
        this.input_element.keypress(function(event) {
            if (event.key == "Enter") {
                self.enter_callback(self.input_element.val(), self.indent);
                self.input_element.val("");
            } else if (event.shiftKey && event.keyCode == 9) {
                self.decreaseIndent();
            } else if (event.keyCode == 9) {
                self.increaseIndent();
            } else if (event.keyCode == 8 && self.input_element.val() == "") {
                self.resetIndent();
            }
        });
        this.input_element.blur(function (event) {
            setTimeout(function() {self.input_element.focus();}, 20);
        });
    },
    VotingControl: function(after_element, vote_options, vote_callback) {
        BaseControl.call(this, {});
        this.vote_callback = vote_callback;
        var self = this;
        this.after_element = after_element;
        this.after_element.hide();
        this.element = $('<div></div>');
        this.button_container = $('<div class="vote-button-container"></div>');
        this.element.append(this.button_container);
        this.element.append(this.after_element);
        this.options = {};
        for (var i = 0; i < vote_options.length; i++) {
            var new_button = $('<button data-voteid="' + vote_options[i].id + '">' + vote_options[i].name + '</button>');
            this.options[vote_options[i].id] = new_button;
            new_button.click(function(event) {
                self.vote_callback($(event.currentTarget).attr('data-voteid'));
                self.button_container.hide();
                self.after_element.show();
            });
            this.button_container.append(new_button);
        }
    },
    InputFieldWithLoadingIcon: function(options) {
        BaseControl.call(this, options);
        if (options.dont_clear) {
            this.dont_clear = true;
        } else {
            this.dont_clear = false;
        }
        this.on_search = options.on_search;
        var self = this;
        this.element = $('<div class="control-container"></div>');
        this.element.append($('<div class="control-label">' + options.label + '</div>'));
        var input_container = $('<div class="control"></div>');
        this.element.append(input_container);
        this.input_field = $('<input type="text"></input>');
        this.input_field.keyup(function (arg) {
            if (arg.key == "Enter") {
                self.doSearch();
            }
        });
        input_container.append(this.input_field);
        var search_button_container = $('<div class="search-button"></div>');
        this.element.append(search_button_container);
        this.search_button = $('<button>' + options.search_button_label + '</button>');
        this.search_button.click(function () {
            self.doSearch();
        });
        search_button_container.append(this.search_button);
        this.loading_icon = $('<img class="loading-icon" src="/static/images/loading.gif">');
        this.loading_icon.hide();
        search_button_container.append(this.loading_icon);
        if (options.success_message) {
            this.success_message = options.success_message;
            this.status_message = $('<div></div>');
            search_button_container.append(this.status_message);
        }
    },
    PopupCreator: function(options) {
        MultiElementControl.call(this, options);
        var self = this;
        this.popup_container = $('<div class="popup-container"></div>');
        this.popup_container.click(function(arg) {
            self.popup_container.hide();
        });
        var popup = $('<div class="popup"></div>');
        popup.click(function(arg) {
            // Without this, any click anywhere inside the popup would
            // propagate up and be seen as a click of the popup
            // container, which should hide the popup.
            arg.stopPropagation();
        });
        this.subcontrol_container = $('<div></div>');
        var button_container = $('<div class="popup-buttons"></div>');
        var ok_button = $('<button>' + options.ok_button_label + '</button>');
        button_container.append(ok_button);
        this.default_after_popup = function(result) {
            self.popup_container.hide();
            console.log(result);
        }
        if (!options.after_popup) {
            // The default after function is to just hide the popup.
            this.after_popup = this.default_after_popup;
        } else {
            this.after_popup = options.after_popup;
        }
        ok_button.click(function() {
            var result = {};
            for (var subcontrol_name in self.subcontrols) {
                if (self.subcontrols.hasOwnProperty(subcontrol_name)) {
                    result[subcontrol_name] = self.subcontrols[subcontrol_name].getValue();
                }
            }
            self.popup_container.hide();
            self.after_popup(result);
        });
        if (!options.cancel_button_label) {
            options.cancel_button_label = 'Cancel';
        }
        var cancel_button = $('<button>' + options.cancel_button_label + '</button>');
        button_container.append(cancel_button);
        cancel_button.click(function() {
            self.popup_container.hide();
        });
        this.popup_container.append(popup);
        popup.append(this.subcontrol_container);
        popup.append(button_container);
        this.elements = [
            this.popup_container
        ];
        this.subcontrols = {};
    },
    PopupButton: function(options) {
        ControlConstructors.PopupCreator.call(this, options);
        var button = $('<button class="popup-button">' + options.button_label + '</button>');
        var self = this;
        button.click(function() {
            self.popup_container.show();
        });
        this.elements.unshift(button);
    },
    TreeDisplay: function(options) {
        BaseControl.call(this, options);
        this.filters = {};
        this.sort_function = function(a, b) {return 1;}
        this.element = $('<div class="tree"></div>');
        this.search_box = $('<input type="text"></input>');
        var self = this;
        this.search_box.keyup(function() {
            var search_term = self.search_box.val();
            window.setTimeout(function() {
                if (search_term != self.search_box.val()) {
                    // Only do the search if the user isn't still typing
                    return;
                }
                self.updateSearchResults(search_term);
            }, 300);
        });
        this.element.append(this.search_box);
        this.code_to_children_map = {};
        this.include_parents_as_leaves = options.include_parents_as_leaves;
        this.all_elements = [];
        this.children = options.children
        this.element.append(this.createSubTree(options.children));
        this.element.find('.leaf,.parent').attr('data-in-search-results', 'true');
    },
    TreeOfLinks: function(options) {
        options.include_parents_as_leaves = false;
        this.base_url = options.base_url;
        ControlConstructors.TreeDisplay.call(this, options);
    },
    TreeSelect: function(options) {
        ControlConstructors.TreeDisplay.call(this, options);
    },
    InstrumentIdSelector: function(options) {
        BaseControl.call(this, options);
        var self = this;
        this.element = $('<div class="entity-search"></div>');
        var name_search_outer_container = $('<div class="control-container"></div>');
        this.element.append(name_search_outer_container);
        name_search_outer_container.append($('<div class="control-label">Name:</div>'));
        var name_search_container = $('<div class="control"></div>');
        this.name_search = new ControlConstructors.search_select({
            identifier_name: 'internal_name',
            search_url: '/datawarehouse_requests/search',
            on_select: function(selected_id, selected_name) {
                self.name_search.reset();
                self.results.add(selected_id, selected_name);
            }
        });
        this.name_search.addElementsTo(name_search_container);
        name_search_outer_container.append(name_search_container);
        this.product_search = new ControlConstructors.InputFieldWithLoadingIcon({
            label: "Product codes:",
            search_button_label: "Add",
            on_search: function(search_term) {
                ajaxPost(
                    '/datawarehouse_requests/product_code_search',
                    search_term.replace(/\s+/g,' ').trim().split(' '),
                    function(data){console.log(data.message);},
                    function(data){
                        for (var i = 0; i < data.results.length; i++) {
                            self.results.add(data.results[i].internal_name, data.results[i].name);
                        }
                        self.product_search.afterSearch();
                    }
                );
            },
        });
        this.product_search.addElementsTo(this.element);
        var peer_group_selector_container = $('<div class="control-container"></div>');
        var peer_group_selector_label = $('<label>By asset class hierarchy:</label>');
        peer_group_selector_container.append(peer_group_selector_label);
        this.element.append(peer_group_selector_container);
        var peer_group_selector = new ControlConstructors.PopupButton({
            button_label: "Select",
            ok_button_label: "Add",
            after_popup: function(result) {
                ajaxPost(
                    '/datawarehouse_requests/subsector_search',
                    result.peer_groups,
                    function(){},
                    function(data){
                        self.results.empty();
                        for (var i = 0; i < data.results.length; i++) {
                            self.results.add(data.results[i].internal_name, data.results[i].name);
                        }
                    }
                );
            }
        });
        var peer_group_tree = new ControlConstructors.TreeSelect({
            children: js_vars['asset_class_hierarchy'],
            include_parents_as_leaves: true
        });
        peer_group_selector.addControl(peer_group_tree, "peer_groups");
        peer_group_selector.addElementsTo(peer_group_selector_container);
        this.selected_instruments_label = $('<div>Selected Instruments: (0)</div>');
        this.element.append(this.selected_instruments_label);
        this.results = new ControlConstructors.orderable_list();
        this.results.onChange = function() {
            self.updateCounts();
        }
        this.results.addElementsTo(this.element);
    },
    CheckboxList: function(options) {
        BaseControl.call(this, options);
        this.name = options.name;
        this.element = $('<div></div>');
        var checkbox_container;
        var checkbox_element;
        if (!options.on_update) {
            options.on_update = function() {};
        }
        this.on_update = options.on_update;
        this.setOptions(options.choices);
    },
    ControlTable: function(options) {
        BaseControl.call(this, options);
        this.element = $('<table class="control-table"></table>');
        this.row_groups = {};
        this.row_group_labels = [];
        this.fields = [];
        this.all_cells = {};
        var header_row = $('<tr><th>Assessment</th></tr>');
        this.element.append($('<thead></thead>').append(header_row));
        if (typeof(options.fields) != 'undefined') {
            for (var i = 0; i < options.fields.length; i++) {
                var next_field = {
                    internal_name: options.fields[i].internal_name,
                    getHtmlValue: function(value) {
                        if (Array.isArray(value)) {
                            return value.join(', ');
                        } else {
                            return value;
                        }
                    }
                };
                header_row.append('<th>' + options.fields[i].label + '</th>');
                if (options.fields[i].type == "boolean") {
                    next_field.getHtmlValue = function(value) {
                        if (value) {
                            return '<img src="/static/images/checkmark.svg">'
                        } else {
                            return '<img src="/static/images/cancel.svg">'
                        }
                    }
                }
                this.fields.push(next_field);
            }
        }
        this.table_body = $('<tbody></tbody>');
        this.element.append(this.table_body);
        if (!options.buttons) {
            this.buttons = [];
        } else {
            this.buttons = options.buttons;
        }
    },
    Paginator: function(options) {
        BaseControl.call(this, options);
        this.pagination = new Pagination(
            options.first,
            options.last,
            options.min,
            options.max
        );
        var self = this;
        this.element = $('<div class="paginator"></div>');
        this.on_page = options.on_page;
        this.previous_link = $('<div class="prev"><a title="Previous Page"><img src="/static/images/left_arrow.png"></a></div>');
        this.previous_link.click(function() {
            self.pagination.stepBack();
            self.on_page(self.pagination);
            self.rePage();
        });
        this.previous_link.hide();
        this.element.append(this.previous_link);

        this.pages_container = $('<div class="list-pages"></div>');
        this.addPageLinks();
        this.element.append(this.pages_container);

        this.next_link = $('<div class="next"><a title="Next Page"><img src="/static/images/right_arrow.png"></a></div>');
        this.next_link.click(function() {
            self.pagination.stepForward();
            self.on_page(self.pagination);
            self.rePage();
        });
        this.element.append(this.next_link);
        this.next_link.hide();
        this.rePage();
    },
    FolderSelect: function(options) {
        BaseControl.call(this, options);
        this.element = $('<div></div>');
        this.folder_selector = new ControlConstructors.select(options.folders);
        this.folder_selector.addElementsTo(this.element);
        this.value_select = new ControlConstructors.select([]);
        this.value_select.setIdLabelNames('internal_name', 'name');
        var self = this;
        this.value_select.on_change = function(selected) {
            if (selected == '') {
                self.on_reset();
                return;
            }
            self.on_change(selected);
        }
        this.on_change = function(selected_id) {};
        this.on_reset = function() {};
        this.get_options_in_folder = options.folder_contents_callback;
        this.get_folder_containing = options.get_folder_callback;
        this.folder_selector.on_change = function(folder_id) {
            self.get_options_in_folder(folder_id, function(folder_contents) {
                folder_contents.unshift({"internal_name": "", "name": ""});
                self.value_select.setOptions(folder_contents);
            });
        }
        this.value_select.addElementsTo(this.element);
    },
    FolderMultiSelect: function(options) {
        BaseControl.call(this, options);
        this.element = $('<div></div>');
        this.folder_selector = new ControlConstructors.select(options.folders);
        this.folder_selector.addElementsTo(this.element);
        many_to_many_container = $('<div class="many-to-many-container"></div>');
        this.element.append(many_to_many_container);
        this.value_select = new ControlConstructors.many_to_many([]);
        this.get_options_in_folder = options.folder_contents_callback;
        this.get_folder_containing = options.get_folder_callback;
        this.get_option_names = options.get_option_names_callback;
        var self = this;
        this.folder_selector.on_change = function(folder_id) {
            if (folder_id == '') {
                self.value_select.emptyOut();
                return;
            }
            self.get_options_in_folder(folder_id, function(folder_contents) {
                self.value_select.addToOut(folder_contents);
            });
        }
        this.value_select.addElementsTo(many_to_many_container);
    }
};

ControlConstructors.select.prototype = Object.create(BaseControl.prototype);
ControlConstructors.select.prototype.constructor = ControlConstructors.select;

ControlConstructors.select.prototype.setOptions = function(options) {
    this.element.children().remove();
    for (var i = 0; i < options.length; i++) {
        this.element.append('<option value="' + options[i][this.id_name] + '">' + options[i][this.label_name] + '</option>');
    }
}

ControlConstructors.select.prototype.setIdLabelNames = function(id_name, label_name) {
    this.id_name = id_name;
    this.label_name = label_name;
}

ControlConstructors.select.prototype.getLabelFromId = function(id_name) {
    return this.element.find('option[value="' + id_name + '"]').text();
}

ControlConstructors.select.prototype.empty = function() {
    this.element.children().remove();
    this.element.append('<option value=""></option>');
}

ControlConstructors.input.prototype = Object.create(BaseControl.prototype);
ControlConstructors.input.prototype.constructor = ControlConstructors.input;

ControlConstructors.multiline.prototype = Object.create(BaseControl.prototype);
ControlConstructors.multiline.prototype.constructor = ControlConstructors.multiline;

ControlConstructors.search_select.prototype = Object.create(BaseControl.prototype);
ControlConstructors.search_select.prototype.constructor = ControlConstructors.search_select;

ControlConstructors.search_select.prototype.getValue = function() {
    if (this.selected == '') {
        return null;
    } else {
        result = {
            name: this.selected_name
        };
        result[this.identifier_name] = this.selected;
        return result
    }
};

ControlConstructors.search_select.prototype.setValue = function(value) {
    if (typeof(value) == 'string') {
        this.search_box.val(value);
    } else if (typeof(value) == 'object' && value !== null) {
        this.selected = value.instrument_id;
        this.search_box.val(value.name);
    }
};

ControlConstructors.search_select.prototype.reset = function() {
    this.search_box.val('');
    this.search_results.hide();
    this.search_results.empty();
};

ControlConstructors.search_select.prototype.disable = function() {
    this.search_box.attr('disabled', true);
};

ControlConstructors.search_select.prototype.enable = function() {
    this.search_box.attr('disabled', false);
};

ControlConstructors.search_select.prototype.onSelect = function(selected, selected_name) {
    this.selected = selected;
    this.selected_name = selected_name;
    this.search_box.val(this.selected_name);
}

ControlConstructors.benchmark_selector.prototype = Object.create(ControlConstructors.search_select.prototype);
ControlConstructors.benchmark_selector.prototype.constructor = ControlConstructors.benchmark_selector;

ControlConstructors.orderable_list.prototype = Object.create(BaseControl.prototype);
ControlConstructors.orderable_list.prototype.constructor = ControlConstructors.orderable_list;

ControlConstructors.orderable_list.prototype.onChange = function() {

}

ControlConstructors.orderable_list.prototype.getElementCount = function() {
    return this.results.children().length;
}

ControlConstructors.orderable_list.prototype.getValue = function() {
    var result = [];
    var result_elements = this.results.children();
    for (var i = 0; i < result_elements.length; i++) {
        result.push({
            name: result_elements[i].text,
            internal_name: result_elements[i].value
        });
    }
    return result;
}

ControlConstructors.orderable_list.prototype.empty = function() {
    this.results.empty();
}

ControlConstructors.orderable_list.prototype.add = function(selected_id, selected_name) {
    if (this.results.find('[value="' + selected_id + '"]').length > 0) {
        return;
    }
    this.results.append($('<option value="' + selected_id + '">' + selected_name + '</option>'));
    this.onChange();
}

ControlConstructors.orderable_list.prototype.bumpSelectedUp = function()
{
    bumpSelected(this.results, getBumpUpPermutation);
};

ControlConstructors.orderable_list.prototype.bumpSelectedDown = function()
{
    bumpSelected(this.results, getBumpDownPermutation);
};

ControlConstructors.orderable_list.prototype.contains = function(element_id) {
    var result_elements = this.results.children();
    for (var i = 0; i < result_elements.length; i++) {
        if (element_id == result_elements[i].value) {
            return true;
        }
    }
    return false;
}

ControlConstructors.multi_search_select.prototype = Object.create(BaseControl.prototype);
ControlConstructors.multi_search_select.prototype.constructor = ControlConstructors.multi_search_select;

ControlConstructors.multi_search_select.prototype.getValue = function() {
    return this.selected;
}

ControlConstructors.multi_search_select.prototype.setValue = function(value) {
    for (var i = 0; i < value.length; i++) {
        this.selected.push(value[i]);
        this.results.add(value[i][this.identifier_name], value[i].name);
    }
}

ControlConstructors.multi_benchmark_select.prototype = Object.create(ControlConstructors.multi_search_select.prototype);
ControlConstructors.multi_benchmark_select.prototype.constructor = ControlConstructors.multi_benchmark_select;

ControlConstructors.row.prototype = Object.create(MultiElementControl.prototype);
ControlConstructors.row.prototype.constructor = ControlConstructors.row;

ControlConstructors.row.prototype.getValue = function() {
    var result = {};
    for (var i=0; i < this.fields.length; i++) {
        result[this.fields[i].name] = this.field_elements[i].getValue();
    }
    return result;
};

ControlConstructors.row.prototype.setValue = function(value) {
    for (var i=0; i < this.fields.length; i++) {
        if (value.hasOwnProperty(this.fields[i].name)) {
            this.field_elements[i].setValue(value[this.fields[i].name]);
        } else {
            this.field_elements[i].reset();
        }
    }
};

ControlConstructors.row.prototype.reset = function() {
    for (var i=0; i < this.fields.length; i++) {
        this.field_elements[i].reset();
    }
};

ControlConstructors.branch.prototype = Object.create(MultiElementControl.prototype);
ControlConstructors.branch.prototype.constructor = ControlConstructors.branch;

ControlConstructors.branch.prototype.getValue = function() {
    var result = {};
    result.choice = this.branch_selector.val();
    var fields = this.fields[result.choice];
    for (var i = 0; i < fields.length; i++) {
        result[fields[i].name] = fields[i].control.getValue();
    }
    return result;
};

ControlConstructors.branch.prototype.setValue = function(value) {
    this.branch_selector.val(value.choice);
    for (var i = 0; i < this.branch_containers.length; i++) {
        if (this.branch_containers[i].name == value.choice) {
            this.branch_containers[i].element.show();
        } else {
            this.branch_containers[i].element.hide();
        }
    }
    var fields = this.fields[value.choice];
    for (var i = 0; i < fields.length; i++) {
        if (value.hasOwnProperty(fields[i].name)) {
            fields[i].control.setValue(value[fields[i].name]);
        } else {
            fields[i].control.reset();
        }
    }
};

ControlConstructors.branch.prototype.reset = function() {
    this.branch_selector.val("");
    for (var i = 0; i < this.branch_containers.length; i++) {
        this.branch_containers[i].element.hide();
    }
};

ControlConstructors.branch.prototype.enable = function() {
    this.branch_selector.attr('disabled', false);
    for (var branch_name in this.fields) {
        if (!this.fields.hasOwnProperty(branch_name)) {
            continue;
        }
        for (var i = 0; i < this.fields[branch_name].length; i++) {
            this.fields[branch_name][i].control.enable();
        }
    }
};

ControlConstructors.branch.prototype.disable = function() {
    this.branch_selector.attr('disabled', true);
    for (var branch_name in this.fields) {
        if (!this.fields.hasOwnProperty(branch_name)) {
            continue;
        }
        for (var i = 0; i < this.fields[branch_name].length; i++) {
            this.fields[branch_name][i].control.disable();
        }
    }
};

ControlConstructors.TableControl.prototype = Object.create(MultiElementControl.prototype);
ControlConstructors.TableControl.prototype.constructor = ControlConstructors.TableControl;

ControlConstructors.TableControl.prototype.addRow = function() {
    var self = this;
    var new_row = new this.row_constructor(this.fields);
    new_row.addElementsTo(this.container_element);
    if (this.is_enabled) {
        var delete_button_container = $('<div class="table-row-delete-button"></div>');
        var delete_button = $('<button>delete</button>');
        delete_button.click(function() {
            new_row.removeElements();
            delete_button_container.remove()
            self.field_rows.splice(self.field_rows.indexOf(new_row), 1);
        });
        delete_button_container.append(delete_button);
        this.container_element.append(delete_button_container);
    }
    this.field_rows.push(new_row);
};

ControlConstructors.TableControl.prototype.getValue = function() {
    var result = [];
    for (var row_number = 0; row_number < this.field_rows.length; row_number++) {
        result.push(this.field_rows[row_number].getValue());
    }
    return result;
};

ControlConstructors.TableControl.prototype.setValue = function(value) {
    if (value === null) {
        return;
    }
    for (var row_number = 0; row_number < value.length; row_number++) {
        if (row_number >= this.field_rows.length) {
            this.addRow();
        }
        this.field_rows[row_number].setValue(value[row_number]);
    }
};

ControlConstructors.PerformanceObjectiveControl.prototype = Object.create(ControlConstructors.TableControl.prototype);
ControlConstructors.PerformanceObjectiveControl.prototype.constructor = ControlConstructors.PerformanceObjectiveControl;

ControlConstructors.RiskObjectiveControl.prototype = Object.create(ControlConstructors.TableControl.prototype);
ControlConstructors.RiskObjectiveControl.prototype.constructor = ControlConstructors.RiskObjectiveControl;

ControlConstructors.many_to_many.prototype = Object.create(MultiElementControl.prototype);
ControlConstructors.many_to_many.prototype.constructor = ControlConstructors.many_to_many;

ControlConstructors.many_to_many.prototype.getInElements = function() {
    var elements_in = [];
    $.each(this.in_select.find('option'), function(index, element) {
        elements_in.push({
            internal_name: element.value,
            name: element.text
        });
    });
    return elements_in;
};

ControlConstructors.many_to_many.prototype.moveSelectedElements = function(from_select, to_select) {
    var selected_ids = from_select.val()
    if (selected_ids === null) {
        selected_ids = [];
    }
    this.moveElements(from_select, to_select, selected_ids);
    this.onChange();
}

ControlConstructors.many_to_many.prototype.moveElements = function(from_select, to_select, selected_ids) {
    for (var i = 0; i < selected_ids.length; i++) {
        var selected_element = from_select.find('option[value="' + selected_ids[i] + '"]');
        if (to_select.find('option[value="' + selected_ids[i] + '"]').length == 0) {
            to_select.append($('<option>', {
                value: selected_ids[i],
                text: selected_element.text(),
                title: selected_element.text()
            }));
        }
        selected_element.remove();
    }
    this.onChange();
};

function permuteArray(arr, permutation)
{
    var result = [];
    for (var i = 0; i < arr.length; i++) {
        result.push(arr[permutation[i]]);
    }
    return result;
}

getBumpUpPermutation = function(arrayLength, indicies)
{
    var result = [0];
    for (var i = 1; i < arrayLength; i++) {
        if (indicies.indexOf(i) >= 0 && indicies.indexOf(i) != i) {
            var previousElement = result.pop();
            result.push(i);
            result.push(previousElement);
        } else {
            result.push(i);
        }
    }
    return result;
};

getBumpDownPermutation = function(arrayLength, indicies)
{
    var result = [arrayLength - 1];
    for (var i = arrayLength - 1; i >= 0; i--) {
        if (indicies.indexOf(i) >= 0 && indicies.length - indicies.indexOf(i) != arrayLength - i) {
            var previousElement = result.shift();
            result.unshift(i);
            result.unshift(previousElement);
        } else {
            result.unshift(i);
        }
    }
    return result;
};

bumpSelected = function(select_element, bumpPermutationCalculator)
{
    var elements_in = []
    var element_ids_in = []
    $.each(select_element.find('option'), function(index, element) {
        elements_in.push([element.value, element.text]);
        element_ids_in.push(element.value);
    });
    var selected_ids = select_element.val();
    var selected_indicies = [];
    for (var i = 0; i < selected_ids.length; i++) {
        selected_indicies.push(element_ids_in.indexOf(selected_ids[i]));
    }
    elements_in = permuteArray(elements_in, bumpPermutationCalculator(elements_in.length, selected_indicies));
    select_element.children().remove();
    for (var i = 0; i < elements_in.length; i++) {
        select_element.append($('<option>', {
            value: elements_in[i][0],
            text: elements_in[i][1],
            title: elements_in[i][1]
        }));
    };
    select_element.val(selected_ids);
};

ControlConstructors.many_to_many.prototype.bumpSelectedUp = function()
{
    bumpSelected(this.in_select, getBumpUpPermutation);
};

ControlConstructors.many_to_many.prototype.bumpSelectedDown = function()
{
    bumpSelected(this.in_select, getBumpDownPermutation);
};

ControlConstructors.many_to_many.prototype.getValue = function() {
    var in_elements = this.getInElements();
    var result = [];
    for (var i = 0; i < in_elements.length; i++) {
        result.push(in_elements[i].internal_name);
    }
    return result;
};

ControlConstructors.many_to_many.prototype.reset = function() {
    var in_elements = this.in_select.children();
    for (var i = 0; i < in_elements.length; i++) {
        this.out_select.append(in_elements[i]);
    }
    this.onChange();
};

ControlConstructors.many_to_many.prototype.setValue = function(data) {
    this.reset();
    this.moveElements(this.out_select, this.in_select, data);
    this.onChange();
};

ControlConstructors.many_to_many.prototype.getElementCounts = function() {
    return {
        in: this.in_select.children().length,
        out: this.out_select.children().length
    }
}

ControlConstructors.many_to_many.prototype.onChange = function() {}

ControlConstructors.many_to_many.prototype.empty = function() {
    this.in_select.children().remove();
    this.out_select.children().remove();
    this.onChange();
}

ControlConstructors.many_to_many.prototype.emptyIn = function() {
    this.in_select.children().remove();
    this.onChange();
}

ControlConstructors.many_to_many.prototype.emptyOut = function() {
    this.out_select.children().remove();
    this.onChange();
}

ControlConstructors.many_to_many.prototype.addToIn = function(new_elements) {
    var new_element_count = new_elements.length;
    for (var i = 0; i < new_element_count; i++) {
        this.in_select.append('<option title="' + new_elements[i].name + '" value="' + new_elements[i].internal_name + '">' + new_elements[i].name + '</option>');
    }
    this.onChange();
}

ControlConstructors.many_to_many.prototype.addToOut = function(new_elements) {
    var new_element_count = new_elements.length;
    for (var i = 0; i < new_element_count; i++) {
        this.out_select.append('<option title="' + new_elements[i].name + '" value="' + new_elements[i].internal_name + '">' + new_elements[i].name + '</option>');
    }
    this.onChange();
}

ControlConstructors.many_to_many_with_context.prototype = Object.create(ControlConstructors.many_to_many.prototype);
ControlConstructors.many_to_many_with_context.prototype.constructor = ControlConstructors.many_to_many_with_context;

ControlConstructors.many_to_many_with_context.prototype.updateVisibleContextControls = function() {
    selected_elements = this.in_select.val();
    for (var in_element in this.context_control_groups) {
        if (this.context_control_groups.hasOwnProperty(in_element)) {
            if ($.inArray(in_element, selected_elements) >= 0) {
                this.context_control_groups[in_element].container.show();
            } else {
                this.context_control_groups[in_element].container.hide();
            }
        }
    }
};

ControlConstructors.many_to_many_with_context.prototype.recreateContextControls = function() {
    var context_values = this.getContextValues();
    this.context_container.children().remove();
    this.context_control_groups = {};
    var in_elements = this.getInElements();
    for (var i = 0; i < in_elements.length; i++) {
        var element_context_container = $('<div style="display:none;"></div>');
        element_context_container.append($('<h4></h4>').text(in_elements[i].name));
        this.context_control_groups[in_elements[i].internal_name] = {
            container: element_context_container,
            fields: {}
        };
        for (var j = 0; j < this.context_fields.length; j++) {
            var element_context = $('<div class="control-container"></div>');
            var control_label = $('<div class="control-label"></div>');
            control_label.text(this.context_fields[j].label);
            element_context.append(control_label);
            var control_container = $('<div class="control"></div>');
            var control = new ControlConstructors[this.context_fields[j].type](this.context_fields[j].options);
            this.context_control_groups[in_elements[i].internal_name].fields[this.context_fields[j].name] = control;
            control.setValue(this.context_fields[j].default);
            control.addElementsTo(control_container);
            element_context.append(control_container);
            element_context_container.append(element_context);
        }
        this.context_container.append(element_context_container);
    }
    this.setContextValues(context_values);
};

ControlConstructors.many_to_many_with_context.prototype.getContextValues = function() {
    var result = {};
    for (var in_element in this.context_control_groups) {
        if (this.context_control_groups.hasOwnProperty(in_element)) {
            result[in_element] = {};
            for (field in this.context_control_groups[in_element].fields) {
                if (this.context_control_groups[in_element].fields.hasOwnProperty(field)) {
                    result[in_element][field] = this.context_control_groups[in_element].fields[field].getValue();
                }
            }
        }
    }
    return result;
};

ControlConstructors.many_to_many_with_context.prototype.setContextValues = function(data) {
    for (var in_element in this.context_control_groups) {
        if (this.context_control_groups.hasOwnProperty(in_element)) {
            if (!data.hasOwnProperty(in_element)) {
                continue;
            }
            for (var i = 0; i < this.context_fields.length; i++) {
                var field = this.context_fields[i].name;
                if (this.context_control_groups[in_element].fields.hasOwnProperty(field)) {
                    this.context_control_groups[in_element].fields[field].setValue(data[in_element][field]);
                }
            }
        }
    }
};

ControlConstructors.many_to_many_with_context.prototype.getValue = function() {
    var in_elements = this.getInElements();
    var context_values = this.getContextValues();
    var result = [];
    for (var i = 0; i < in_elements.length; i++) {
        var element_data = context_values[in_elements[i].internal_name];
        element_data.internal_name = in_elements[i].internal_name;
        element_data.position = i;
        result.push(element_data);
    }
    return result;
};

ControlConstructors.many_to_many_with_context.prototype.reset = function() {
    var in_elements = this.in_select.children();
    for (var i = 0; i < in_elements.length; i++) {
        this.out_select.append(in_elements[i]);
    }
    this.context_container.children().remove();
};

ControlConstructors.many_to_many_with_context.prototype.setValue = function(data) {
    this.reset();
    var elements_to_move = [];
    var context_data = {}
    for (var i = 0; i < data.length; i++) {
        elements_to_move.push(data[i].internal_name);
        context_data[data[i].internal_name] = data[i]
    }
    this.moveElements(this.out_select, this.in_select, elements_to_move);
    this.recreateContextControls();
    this.setContextValues(context_data);
};

ControlConstructors.DisplayTable.prototype = Object.create(BaseControl.prototype);
ControlConstructors.DisplayTable.prototype.constructor = ControlConstructors.DisplayTable;

ControlConstructors.DisplayTable.prototype.addRow = function(internal_name, name)
{
    var new_row = $('<tr></tr>');
    new_row.append('<td>' + name + '</td>');
    this.cells[internal_name] = {};
    for (var i = 0; i < this.column_ids.length; i++) {
        var new_cell = $('<td></td>');
        this.cells[internal_name][this.column_ids[i]] = new_cell;
        new_cell.append(this.default_value);
        new_row.append(new_cell);
    }
    this.rows[internal_name] = new_row;
    this.row_names[internal_name] = name;
    this.table_body.append(new_row);
}

ControlConstructors.DisplayTable.prototype.setCellValue = function(row_id, column_id, value)
{
    this.cells[row_id][column_id].text(value);
}

ControlConstructors.DisplayTable.prototype.getCellValue = function(row_id, column_id)
{
    return this.cells[row_id][column_id].text();
}

ControlConstructors.DisplayTable.prototype.getNumericCellValue = function(row_id, column_id)
{
    var cell_value = this.cells[row_id][column_id].text();
    if (cell_value == "-") {
        // This means that all the data sources that returned null appear at the end
        return null
    } else {
        return parseFloat(cell_value.replace(/[,()$]/g,''));
    }
}

ControlConstructors.DisplayTable.prototype.getColumnOrdering = function(column_id)
{
    var result = [];
    var nulls = [];
    for (var row_id in this.cells) {
        if (this.cells.hasOwnProperty(row_id)) {
            var column_value = this.getNumericCellValue(row_id, column_id);
            if (column_value == null) {
                nulls.push({
                    id: row_id,
                    rank: "-"
                })
            } else {
                for (var i = 0; i < result.length; i++) {
                    if (column_value > result[i].value) {
                        break;
                    }
                }
                result.splice(i, 0, {
                    value: column_value,
                    id: row_id,
                });
            }
        }
    }
    if (result.length > 0) {
        result[0].rank = "1";
        for (var i = 1; i < result.length; i++) {
            if (result[i].value < result[i - 1].value) {
                result[i].rank = (i + 1);
            } else {
                result[i].rank = result[i-1].rank;
            }
        }
    }
    result = result.concat(nulls);
    return result;
}

ControlConstructors.DisplayTable.prototype.getRowNameOrdering = function()
{
    var result = [];
    for (var row_id in this.cells) {
        if (this.cells.hasOwnProperty(row_id)) {
            var column_name = this.row_names[row_id];
            for (var i = 0; i < result.length; i++) {
                if (column_name < result[i].value) {
                    break;
                }
            }
            result.splice(i, 0, {
                value: column_name,
                id: row_id
            });
        }
    }
    return result;
}

ControlConstructors.DisplayTable.prototype.orderRowsBy = function(column_id, order_by_name)
{
    if (order_by_name) {
        var ordering = this.getRowNameOrdering();
    } else {
        var ordering = this.getColumnOrdering(column_id);
    }

    if (this.current_ranking_column == column_id) {
        this.current_ranking_direction = 1 - this.current_ranking_direction;
    } else {
        this.current_ranking_column = column_id;
        this.current_ranking_direction = 1;
    }
    if (this.current_ranking_direction) {
        for (var i = 0; i < ordering.length; i++) {
            this.table_body.append(this.rows[ordering[i].id]);
        }
    } else {
        for (var i = ordering.length - 1; i >= 0; i--) {
            this.table_body.append(this.rows[ordering[i].id]);
        }
    }
}

ControlConstructors.DisplayTable.prototype.reset = function()
{
    this.cells = {};
    this.table_body.children().remove();
}

// Methods on Variable column display table.
ControlConstructors.VariableColumnDisplayTable.prototype = Object.create(BaseControl.prototype);
ControlConstructors.VariableColumnDisplayTable.prototype.constructor = ControlConstructors.VariableColumnDisplayTable;

ControlConstructors.VariableColumnDisplayTable.prototype.addColumn = function(column_id, column_label)
{
    this.cells[column_id] = {};
    for (var i = 0; i < this.row_ids.length; i++) {
        var new_cell = $('<td>' + this.default_value + '</td>');
        this.cells[column_id][this.row_ids[i]] = new_cell;
        this.rows[this.row_ids[i]].append(new_cell);
    }
    this.header_row.append($('<td>' + column_label + '</td>'));
}

ControlConstructors.VariableColumnDisplayTable.prototype.setCellValue = function(column_id, row_id, value)
{
    this.cells[column_id][row_id].text(value);
}

// Methods of DynamicList.
ControlConstructors.DynamicList.prototype = Object.create(BaseControl.prototype);
ControlConstructors.DynamicList.prototype.constructor = ControlConstructors.DynamicList;

ControlConstructors.DynamicList.prototype.add = function(key, value)
{
    if (!this.list_items.hasOwnProperty(key)) {
        var new_item = $('<li>' + value + '</li>');
        this.list_items[key] = new_item;
        this.element.append(new_item);
    }
}

ControlConstructors.DynamicList.prototype.remove = function(key)
{
    if (this.list_items.hasOwnProperty(key)) {
        this.list_items[key].remove();
        delete this.list_items[key];
    }
}

ControlConstructors.DynamicList.prototype.reset = function()
{
    for (var item in this.list_items) {
        if (this.list_items.hasOwnProperty(item)) {
            this.list_items[item].remove();
            delete this.list_items[item];
        }
    }
}

ControlConstructors.IndentedList.prototype = Object.create(ControlConstructors.DynamicList.prototype);
ControlConstructors.IndentedList.prototype.constructor = ControlConstructors.IndentedList;

ControlConstructors.IndentedList.prototype.add = function(key, value, indent)
{
    if (!this.list_items.hasOwnProperty(key)) {
        var new_item = $('<li>' + value + '</li>');
        new_item.css('padding-left', '' + (indent * this.indentation_amount) + 'px');
        this.list_items[key] = new_item;
        this.element.append(new_item);
    }
}

ControlConstructors.IndentedList.prototype.addBefore = function(key, value, indent)
{
    if (!this.list_items.hasOwnProperty(key)) {
        var new_item = $('<li>' + value + '</li>');
        new_item.css('padding-left', '' + (indent * this.indentation_amount) + 'px');
        this.list_items[key] = new_item;
        this.element.prepend(new_item);
    }
}

// Methods of indented input, a text box that can also handle whether the input was "indented"
ControlConstructors.IndentedInput.prototype = Object.create(MultiElementControl.prototype);
ControlConstructors.IndentedInput.prototype.constructor = ControlConstructors.IndentedInput;

ControlConstructors.IndentedInput.prototype.refresh = function()
{
    var new_margin = (this.indent * this.indent_width);
    this.input_element.css("margin-left", '' + new_margin + "px");
    this.input_element.css("width", "" + (this.original_width - new_margin) + "px");
}

ControlConstructors.IndentedInput.prototype.increaseIndent = function()
{
    this.indent++;
    this.refresh();
}

ControlConstructors.IndentedInput.prototype.decreaseIndent = function()
{
    this.indent--;
    if (this.indent <= 0) {
        this.indent = 0;
    }
    this.refresh();
}

ControlConstructors.IndentedInput.prototype.resetIndent = function()
{
    this.indent = 0;
    this.refresh();
}

// Methods of Screen Pager, it inherrits from BaseControl, just one element
ControlConstructors.ScreenPager.prototype = Object.create(BaseControl.prototype);
ControlConstructors.ScreenPager.prototype.constructor = ControlConstructors.ScreenPager;

ControlConstructors.ScreenPager.prototype.switchTo = function(screen_name)
{
    if (this.screens.hasOwnProperty(screen_name)) {
        for (var i = 0; i < this.screen_ids.length; i++) {
            if (screen_name == this.screen_ids[i]) {
                this.screens[screen_name].show();
            } else {
                this.screens[this.screen_ids[i]].hide();
            }
        }
    }
}

ControlConstructors.VotingControl.prototype = Object.create(BaseControl.prototype);
ControlConstructors.VotingControl.prototype.constructor = ControlConstructors.VotingControl;

ControlConstructors.VotingControl.prototype.getChoiceLabel = function(choice_id)
{
    return this.options[choice_id].text();
}

ControlConstructors.VotingControl.prototype.setChoiceLabel = function(choice_id, new_label)
{
    this.options[choice_id].text(new_label);
}

ControlConstructors.VotingControl.prototype.reset = function()
{
    this.after_element.hide();
    this.button_container.show();
}

ControlConstructors.VotingControl.prototype.close = function()
{
    this.after_element.show();
    this.button_container.hide();
}

ControlConstructors.InputFieldWithLoadingIcon.prototype = Object.create(BaseControl.prototype);
ControlConstructors.InputFieldWithLoadingIcon.prototype.constructor = ControlConstructors.InputFieldWithLoadingIcon;

ControlConstructors.InputFieldWithLoadingIcon.prototype.startLoading = function()
{
    this.loading_icon.show();
    this.search_button.attr('disabled', true);
    this.input_field.attr('disabled', true);
}

ControlConstructors.InputFieldWithLoadingIcon.prototype.stopLoading = function()
{
    this.loading_icon.hide();
    this.search_button.removeAttr('disabled');
    this.input_field.removeAttr('disabled');
}

ControlConstructors.InputFieldWithLoadingIcon.prototype.setStatus = function(status_message)
{
    if (this.success_message) {
        this.status_message.text(status_message);
        window.setTimeout(function() {
            self.status_message.text('');
        }, 5000);
    }
}

ControlConstructors.InputFieldWithLoadingIcon.prototype.afterSearch = function()
{
    this.stopLoading();
    if (!this.dont_clear) {
        this.input_field.val('');
    }

    var self = this;
    if (this.success_message) {
        self.status_message.text(self.success_message);
        window.setTimeout(function() {
            self.status_message.text('');
        }, 5000);
    }
}

ControlConstructors.InputFieldWithLoadingIcon.prototype.getValue = function()
{
    return this.input_field.val();
}

ControlConstructors.InputFieldWithLoadingIcon.prototype.setValue = function(value)
{
    return this.input_field.val(value);
}

ControlConstructors.InputFieldWithLoadingIcon.prototype.doSearch = function()
{
    // options.on_search is a function that should take a
    // string as input and do the search (whatever that may be)
    // with that string. When the search is done, this function
    // should call the afterSearch method on the
    // InputFieldWithLoadingIcon instance.
    this.startLoading();
    this.on_search(this.input_field.val());
}

ControlConstructors.PopupCreator.prototype = Object.create(MultiElementControl.prototype);
ControlConstructors.PopupCreator.prototype.constructor = ControlConstructors.PopupCreator;

ControlConstructors.PopupCreator.prototype.createPopup = function(options)
{
    this.subcontrol_container.children().remove();
    for (var i = 0; i < options.fields.length; i++) {
        if (options.fields[i].label) {
            var control_label = $('<div class="popup-control-label">' + options.fields[i].label + '</div>');
            this.subcontrol_container.append(control_label);
        }
        var new_control = new ControlConstructors[options.fields[i].type](options.fields[i].options);
        new_control.addElementsTo(this.subcontrol_container);
        this.subcontrols[options.fields[i].name] = new_control;
    }
    if (options.message) {
        var popup_message = $('<div class="popup-control-label">' + options.message + '</div>');
        this.subcontrol_container.append(popup_message);
    }
    if (options.after_popup) {
        this.after_popup = options.after_popup;
    } else {
        this.after_popup = this.default_after_popup;
    }
    this.popup_container.show();
}

ControlConstructors.PopupButton.prototype = Object.create(ControlConstructors.PopupCreator.prototype);
ControlConstructors.PopupButton.prototype.constructor = ControlConstructors.PopupButton;

ControlConstructors.PopupButton.prototype.addControl = function(control, name)
{
    control.addElementsTo(this.subcontrol_container);
    this.subcontrols[name] = control;
}

ControlConstructors.PopupButton.prototype.createPopup = function() {
    // Overridden to do nothing
}

ControlConstructors.TreeDisplay.prototype = Object.create(BaseControl.prototype);
ControlConstructors.TreeDisplay.prototype.constructor = ControlConstructors.TreeDisplay;

ControlConstructors.TreeDisplay.prototype.recursivelySort = function(children) {
    if (!children) {
        return [];
    }
    var result = [];
    for (var i = 0; i < children.length; i++) {
        var next_child = {};
        for (var property in children[i]) {
            if (children[i].hasOwnProperty(property) && property != 'children') {
                next_child[property] = children[i][property];
            }
        }
        next_child.children = this.recursivelySort(children[i].children)
        result.push(next_child);
    }
    result.sort(this.sort_function);
    return result;
}

ControlConstructors.TreeDisplay.prototype.recursivelyFilter = function(children) {
    if (!children) {
        return [];
    }
    var result = [];
    for (var i = 0; i < children.length; i++) {
        var next_child = {};
        for (var property in children[i]) {
            if (children[i].hasOwnProperty(property) && property != 'children') {
                next_child[property] = children[i][property];
            }
        }
        next_child.children = this.recursivelyFilter(children[i].children)
        if (next_child.children.length > 0) {
            result.push(next_child);
        } else {
            var is_filtered_out = false;
            for (var filter_name in this.filters) {
                if (this.filters.hasOwnProperty(filter_name) && !this.filters[filter_name](next_child)) {
                    is_filtered_out = true;
                    break;
                }
            }
            if (!is_filtered_out) {
                result.push(next_child);
            }
        }
    }
    return result;
}

ControlConstructors.TreeDisplay.prototype.sort = function(compare) {
    this.sort_function = compare;
    this.refilterAndSort();
}

ControlConstructors.TreeDisplay.prototype.removeFilter = function(filter_name) {
    delete this.filters[filter_name];
    this.refilterAndSort();
}

ControlConstructors.TreeDisplay.prototype.filter = function(filter_name, filter) {
    this.filters[filter_name] = filter;
    this.refilterAndSort();
}

ControlConstructors.TreeDisplay.prototype.refilterAndSort = function() {
    this.element.find('.children').remove();
    this.element.append(
        this.createSubTree(
            this.recursivelySort(
                this.recursivelyFilter(this.children)
            )
        )
    );
}

ControlConstructors.TreeDisplay.prototype.markNodeAsIn = function(code)
{
    this.element.find('[data-node-code="' + code + '"][data-is-parent-leaf="false"]').attr('data-in-search-results', 'true');
}

ControlConstructors.TreeDisplay.prototype.markChildrenAsIn = function(code)
{
    if (this.code_to_children_map[code]) {
        this.code_to_children_map[code].find('.leaf,.parent').attr('data-in-search-results', 'true');
    }
}

ControlConstructors.TreeDisplay.prototype.recursivelySearchChildren = function(tree, search_words)
{
    // recursively set a node to be in if it or any of its children
    // are a match. if a node is a match then set all its children
    // to be in as well.
    if (!tree) {
        return false
    }
    var search_result_found;
    var any_search_result_found = false;
    for (var i = 0; i < tree.length; i++) {
        search_result_found = false;
        for (var j = 0; j < search_words.length; j++) {
            if (tree[i].name.toUpperCase().indexOf(search_words[j]) !== -1) {
                this.markNodeAsIn(tree[i].code);
                this.markChildrenAsIn(tree[i].code);
                search_result_found = true;
                any_search_result_found = true;
                break;
            }
        }
        if (!search_result_found) {
            if (this.recursivelySearchChildren(tree[i].children, search_words)) {
                this.markNodeAsIn(tree[i].code);
                any_search_result_found = true;
            }
        }
    }
    return any_search_result_found;
}

ControlConstructors.TreeDisplay.prototype.updateSearchResults = function(search_term)
{
    if (search_term.trim() == '') {
        // If the search box is empty, show everything
        this.element.find('.leaf,.parent').attr('data-in-search-results', 'true');
    } else {
        // Start by ruling everything out
        this.element.find('.leaf,.parent').attr('data-in-search-results', 'false');
        // split the search term into words
        search_words = search_term.split(' ');
        for (var i = 0; i < search_words.length; i++) {
            if (search_words[i] == '') {
                search_words.splice(i, 1);
                i--;
            } else {
                search_words[i] = search_words[i].toUpperCase();
            }
        }
        this.recursivelySearchChildren(this.children, search_words);
    }
}

ControlConstructors.TreeDisplay.prototype.createSubTree = function(children)
{
    var result = $('<div class="children"></div>');
    if (typeof(children) == "undefined") {
        return result;
    }
    var self = this;

    function onParentNodeClick(arg)
    {
        self.code_to_children_map[arg.currentTarget.dataset.nodeCode].toggle();
        arg.stopPropagation();
    }

    function onLeafNodeClick(arg)
    {
        arg.stopPropagation();
    }

    var children_length = children.length;
    var node;
    var subtree;
    for (var i = 0; i < children_length; i++) {
        if (children[i].hasOwnProperty('children') && children[i].children.length > 0) {
            node = this.createParentNode(children[i].code, children[i].name);
            node.attr("data-is-parent-leaf", 'false')
            this.all_elements.push({
                'name': children[i].name.toUpperCase(),
                'node': node
            });
            node.click(onParentNodeClick);
            sub_tree = this.createSubTree(children[i].children);
            if (this.include_parents_as_leaves) {
                var parent_leaf = this.createLeafNode(children[i].code, children[i].name, "Just in ");
                parent_leaf.attr("data-is-parent-leaf", 'true')
                this.all_elements.push({
                    'name': children[i].name.toUpperCase(),
                    'node': parent_leaf
                });
                parent_leaf.click(onLeafNodeClick);
                sub_tree.prepend(parent_leaf);
            }
            this.code_to_children_map[children[i].code] = sub_tree;
            node.append(sub_tree);
        } else {
            node = this.createLeafNode(children[i].code, children[i].name);
            node.attr("data-is-parent-leaf", 'false')
            this.all_elements.push({
                'name': children[i].name.toUpperCase(),
                'node': node
            });
            node.click(onLeafNodeClick);
        }
        result.append(node);
    }
    return result;
}

ControlConstructors.TreeOfLinks.prototype = Object.create(ControlConstructors.TreeDisplay.prototype);
ControlConstructors.TreeOfLinks.prototype.constructor = ControlConstructors.TreeOfLinks;

ControlConstructors.TreeOfLinks.prototype.createLeafNode = function(code, name, name_prefix)
{
    if (!name_prefix) {
        name_prefix = "";
    }
    return $('<div class="leaf" data-node-code="' + code + '"><a href="'+ this.base_url + code + '" class="tree-node-label">' + name_prefix + name + '</a></div>');
}

ControlConstructors.TreeOfLinks.prototype.createParentNode = function(code, name)
{
    var node = $('<div class="parent" data-node-code="' + code + '"><div class="tree-node-label">' + name + '</div></div>');
    return node;
}

ControlConstructors.TreeOfLinks.prototype.getValue = function()
{
    return [];
}

ControlConstructors.TreeSelect.prototype = Object.create(ControlConstructors.TreeDisplay.prototype);
ControlConstructors.TreeSelect.prototype.constructor = ControlConstructors.TreeSelect;

ControlConstructors.TreeSelect.prototype.createLeafNode = function(code, name, name_prefix)
{
    if (!name_prefix) {
        name_prefix = "";
    }
    var node = $('<div class="leaf" data-node-code="' + code + '"></div>');
    node.append($('<input type="checkbox" value="' + code + '"></input>'));
    node.append($('<div class="tree-node-label">' + name_prefix + name + '</div>'));
    return node;
}

ControlConstructors.TreeSelect.prototype.createParentNode = function(code, name)
{
    var node = $('<div class="parent" data-node-code="' + code + '"></div>');
    var parent_checkbox = $('<input data-node-code="' + code + '" value="_parent" type="checkbox"></input>');
    var self = this;
    parent_checkbox.click(function(arg) {
        arg.stopPropagation();
        var clicked_code = arg.currentTarget.dataset.nodeCode;
        var is_checked = $(arg.currentTarget).is(':checked');
        self.code_to_children_map[clicked_code].find('input[type="checkbox"]').prop('checked', is_checked);
    });
    node.append(parent_checkbox);
    node.append($('<div class="tree-node-label">' + name + '</div>'));
    return node;
}

ControlConstructors.TreeSelect.prototype.getValue = function()
{
    var selected = this.element.find('input:checked');
    var number_selected = selected.length;
    var result = [];
    for (var i = 0; i < number_selected; i++) {
        if (selected[i].value != '_parent') {
            result.push(selected[i].value);
        }
    }
    return result;
}

ControlConstructors.InstrumentIdSelector.prototype = Object.create(BaseControl.prototype);
ControlConstructors.InstrumentIdSelector.prototype.constructor = ControlConstructors.InstrumentIdSelector;

ControlConstructors.InstrumentIdSelector.prototype.updateCounts = function() {
    var counts = this.results.getElementCount();
    this.selected_instruments_label.text('Selected Instruments: (' + counts + ')');
}

ControlConstructors.InstrumentIdSelector.prototype.getValue = function() {
    return this.results.getValue();
}

ControlConstructors.InstrumentIdSelector.prototype.setValue = function(instruments) {
    this.results.empty();
    for (var i = 0; i < instruments.length; i++) {
        this.results.add(instruments[i].internal_name, instruments[i].name);
    }
}

ControlConstructors.InstrumentIdSelector.prototype.add = function(instrument) {
    this.results.add(instrument.internal_name, instrument.name);
}

ControlConstructors.InstrumentIdSelector.prototype.reset = function() {
    this.results.empty();
}

ControlConstructors.InstrumentIdSelector.prototype.contains = function(element_id) {
    return this.results.contains(element_id);
}

ControlConstructors.CheckboxList.prototype = Object.create(BaseControl.prototype);
ControlConstructors.CheckboxList.prototype.constructor = ControlConstructors.CheckboxList;

ControlConstructors.CheckboxList.prototype.getValue = function() {
    var result = [];
    var checked = this.element.find('input:checked');
    for (var i = 0; i < checked.length; i++) {
        result.push(checked[i].value)
    }
    return result;
}

ControlConstructors.CheckboxList.prototype.setValue = function(value) {
    var checkboxes = this.element.find('input');
    for (var i = 0; i < checkboxes.length; i++) {
        var is_set = false;
        for (var j = 0; j < value.length; j++) {
            if (value[j] == checkboxes[i].value) {
                checkboxes[i].setAttribute('checked', 'checked');
                is_set = true;
                break;
            }
        }
        if (!is_set) {
            checkboxes[i].removeAttribute('checked');
        }
    }
    this.on_update(value);
}

ControlConstructors.CheckboxList.prototype.getSelectedOptions = function() {
    // Like getValue, except it returns a list of objects that can be
    // passed to setOptions
    var result = []
    var checked = this.element.find('input:checked');
    for (var i = 0; i < checked.length; i++) {
        result.push({
            value: checked[i].value,
            label: checked[i].parentElement.textContent
        })
    }
    return result;
}

ControlConstructors.CheckboxList.prototype.setOptions = function(choices)
{
    var self = this;
    var current_value = this.getValue();
    this.element.children().remove();
    for (var i = 0; i < choices.length; i++) {
        checkbox_container = $('<div class="radio-label"></div>');
        checkbox_element = $('<input type="checkbox" name="' + this.name + '" value="' + choices[i].value + '"><span>' + choices[i].label + '</span></input>');
        checkbox_element.click(function() {
            self.on_update(self.getValue());
        });
        checkbox_container.append(checkbox_element);
        this.element.append(checkbox_container);
    }
    this.setValue(current_value);
}

ControlConstructors.ControlTable.prototype = Object.create(BaseControl.prototype);
ControlConstructors.ControlTable.prototype.constructor = ControlConstructors.ControlTable;

ControlConstructors.ControlTable.prototype.addRowToGroup = function(group_name, row)
{
    if (this.row_groups[group_name].group_number >= this.row_group_labels.length - 1) {
        this.table_body.append(row);
    } else {
        var index = this.row_groups[group_name].group_number + 1;
        this.row_group_labels[index].before(row);
    }
    this.row_groups[group_name].rows.push(row);
}

ControlConstructors.ControlTable.prototype.addGrouping = function(group_name)
{
    var new_row_group_label = $('<tr class="row-group-label"><th>' + group_name + '</th></tr>');
    for (var i = 0; i < this.fields.length; i++) {
        new_row_group_label.append('<td></td>');
    }
    for (var i = 0; i < this.buttons.length; i++) {
        new_row_group_label.append('<td class="button-cell"></td>');
    }
    this.row_group_labels.push(new_row_group_label);
    this.table_body.append(new_row_group_label);
    var index = this.row_group_labels.length - 1;
    this.row_groups[group_name] = {
        rows: [],
        group_number: index
    };
}

ControlConstructors.ControlTable.prototype.createHtmlRow = function(data)
{
    var new_row = $('<tr class="control-row"><td>' + data.name + '</td></tr>');
    this.all_cells[data.internal_name] = {};
    for (var i = 0; i < this.fields.length; i++) {
        var next_cell = $('<td>' + this.fields[i].getHtmlValue(data[this.fields[i].internal_name]) + '</td>');
        new_row.append(next_cell);
        this.all_cells[data.internal_name][this.fields[i].internal_name] = next_cell;
    }
    var self = this;
    for (var i = 0; i < this.buttons.length; i++) {
        var next_button = $('<button data-button-id="' + i + '" data-row-id="' + data.internal_name + '">' + this.buttons[i].label + '</button>');
        next_button.click(function (element) {
            self.buttons[element.target.dataset.buttonId].on_click(element.target.dataset.rowId);
        });
        var next_cell = $('<td class="button-cell"></td>');
        next_cell.append(next_button);
        new_row.append(next_cell);
    }
    return new_row;
}

ControlConstructors.ControlTable.prototype.removeRows = function()
{
    this.all_cells = {};
    this.row_groups = {}
    this.table_body.children().remove();
}

ControlConstructors.ControlTable.prototype.addRow = function(data)
{
    if (!this.row_groups.hasOwnProperty(data.grouping)) {
        this.addGrouping(data.grouping);
    }
    var new_row = this.createHtmlRow(data);
    this.addRowToGroup(data.grouping, new_row);
}

ControlConstructors.ControlTable.prototype.addRows = function(rows)
{
    for (var i = 0; i < rows.length; i++) {
        this.addRow(rows[i]);
    }
}

ControlConstructors.ControlTable.prototype.updateRow = function(data) {
    for (var i = 0; i < this.fields.length; i++) {
        this.all_cells[data.internal_name][this.fields[i].internal_name].html(this.fields[i].getHtmlValue(data[this.fields[i].internal_name]));
    }
}

ControlConstructors.Paginator.prototype = Object.create(BaseControl.prototype);
ControlConstructors.Paginator.prototype.constructor = ControlConstructors.Paginator;

function Pagination(first, last, min, max)
{
    this.first = first;
    this.last = last;
    this.step_size = this.last - this.first;
    this.min = min;
    this.max = max;
}

Pagination.prototype.stepBack = function()
{
    this.first = this.first - this.step_size;
    if (this.first < this.min) {
        this.first = this.min;
    }
    this.last = this.first + this.step_size;
}

Pagination.prototype.stepForward = function()
{
    this.first = this.first + this.step_size;
    this.last = this.first + this.step_size;
    if (this.last > this.max) {
        this.last = this.max;
    }
}

Pagination.prototype.atStart = function()
{
    return this.first == this.min;
}

Pagination.prototype.atEnd = function()
{
    return this.last == this.max;
}

Pagination.prototype.pageCount = function()
{
    return Math.ceil((this.max - this.min) / this.step_size) + 1;
}

Pagination.prototype.getPageMin = function(page_number)
{
    var result = this.min + (page_number - 1) * (this.step_size);
    if (result < this.min) {
        return this.min;
    }
    return result;
}

Pagination.prototype.getPageMax = function(page_number)
{
    var result = this.min + (page_number) * (this.step_size);
    if (result > this.max) {
        return this.max
    }
    return result;
}

Pagination.prototype.toPage = function(page_number)
{
    this.first = this.getPageMin(page_number);
    this.last = this.getPageMax(page_number);
}

Pagination.prototype.getPageNumber = function()
{
    return Math.floor((this.first - this.min) / this.step_size) + 1;
}

ControlConstructors.Paginator.prototype.addPageLinks = function() {
    var self = this;
    this.pages_container.children().remove();
    this.pages_container.append($('<span class="page-label">Page:</span>'));
    this.page_links = [];
    for (var i = 1; i < this.pagination.pageCount(); i++) {
        var page_link = $('<a data-page-number="' + i + '">' + i + '</a>');
        page_link.click(function(e) {
            var page_number = parseInt(e.target.dataset.pageNumber);
            self.pagination.toPage(page_number);
            self.rePage();
            self.on_page(self.pagination);
        });
        this.page_links.push(page_link);
        this.pages_container.append(page_link);
    }
}

ControlConstructors.Paginator.prototype.rePage = function() {
    if (!this.pagination.atStart()) {
        this.previous_link.show();
    } else {
        this.previous_link.hide();
    }
    if (!this.pagination.atEnd()) {
        this.next_link.show();
    } else {
        this.next_link.hide();
    }
    this.pages_container.children().removeClass('selected');
    this.page_links[this.pagination.getPageNumber() - 1].addClass('selected');
}

ControlConstructors.FolderSelect.prototype = Object.create(BaseControl.prototype);
ControlConstructors.FolderSelect.prototype.constructor = ControlConstructors.FolderSelect;

ControlConstructors.FolderSelect.prototype.getValue = function()
{
    return this.value_select.getValue();
};

ControlConstructors.FolderSelect.prototype.setValue = function(value)
{
    if (!value) {
        this.reset();
        return;
    }
    var self = this;
    this.get_folder_containing(value, function(folder) {
        self.folder_selector.setValue(folder);
        self.get_options_in_folder(folder, function(options){
            self.value_select.setOptions(options);
            self.value_select.setValue(value);
        });
    });
};

ControlConstructors.FolderSelect.prototype.reset = function()
{
    this.value_select.empty();
    this.folder_selector.setValue('');
}

ControlConstructors.FolderMultiSelect.prototype = Object.create(BaseControl.prototype);
ControlConstructors.FolderMultiSelect.prototype.constructor = ControlConstructors.FolderMultiSelect;

ControlConstructors.FolderMultiSelect.prototype.getValue = function()
{
    return this.value_select.getValue();
};

ControlConstructors.FolderMultiSelect.prototype.setValue = function(value)
{
    var self = this;
    this.get_option_names(value, function(values_with_names) {
        self.value_select.empty();
        self.value_select.addToIn(values_with_names);
    });
};

ControlConstructors.FolderMultiSelect.prototype.reset = function()
{
    this.value_select.empty();
    this.folder_selector.setValue('');
}

