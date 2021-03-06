/**
 * # Comparison Component
 *
 * Compares two objects
 */
/obj/item/circuit_component/compare/comparison
	display_name = "Comparison"

	input_port_amount = 2
	var/current_type = PORT_TYPE_ANY

GLOBAL_LIST_INIT(comp_comparison_options, list(
	COMP_COMPARISON_EQUAL,
	COMP_COMPARISON_NOT_EQUAL,
	COMP_COMPARISON_GREATER_THAN,
	COMP_COMPARISON_LESS_THAN,
	COMP_COMPARISON_GREATER_THAN_OR_EQUAL,
	COMP_COMPARISON_LESS_THAN_OR_EQUAL
))

/obj/item/circuit_component/compare/comparison/Initialize()
	options = GLOB.comp_comparison_options
	return ..()

/obj/item/circuit_component/compare/comparison/input_received(datum/port/input/port)
	switch(current_option)
		if(COMP_COMPARISON_EQUAL, COMP_COMPARISON_NOT_EQUAL)
			if(current_type != PORT_TYPE_ANY)
				current_type = PORT_TYPE_ANY
				input_ports[1].set_datatype(PORT_TYPE_ANY)
				input_ports[2].set_datatype(PORT_TYPE_ANY)
		else
			if(current_type != PORT_TYPE_NUMBER)
				current_type = PORT_TYPE_NUMBER
				input_ports[1].set_datatype(PORT_TYPE_NUMBER)
				input_ports[2].set_datatype(PORT_TYPE_NUMBER)
	return ..()


/obj/item/circuit_component/compare/comparison/do_comparisons(list/ports)
	if(length(ports) < input_port_amount)
		return FALSE

	// Comparison component only compares the first two ports
	var/input1 = input_ports[1].input_value
	var/input2 = input_ports[2].input_value

	switch(current_option)
		if(COMP_COMPARISON_EQUAL)
			return input1 == input2
		if(COMP_COMPARISON_NOT_EQUAL)
			return input1 != input2
		if(COMP_COMPARISON_GREATER_THAN)
			return input1 > input2
		if(COMP_COMPARISON_GREATER_THAN_OR_EQUAL)
			return input1 >= input2
		if(COMP_COMPARISON_LESS_THAN)
			return input1 < input2
		if(COMP_COMPARISON_LESS_THAN_OR_EQUAL)
			return input1 <= input2
