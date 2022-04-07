#define MAX_MATERIAL_REWARD 100
#define CREDIT_COOLDOWN_LENGTH (5 SECONDS)

//All devices that link into the R&D console fall into thise type for easy identification and some shared procs.
/obj/machinery/rnd
	name = "R&D Device"
	icon = 'icons/obj/machines/research.dmi'
	density = TRUE
	use_power = IDLE_POWER_USE
	var/busy = FALSE
	var/hacked = FALSE
	var/console_link = TRUE //allow console link.
	var/disabled = FALSE
	var/obj/item/loaded_item = null //the item loaded inside the machine (currently only used by experimentor and destructive analyzer)
	/// Ref to global science techweb.
	var/datum/techweb/stored_research
	var/static/datum/bank_account/bank_account
	var/static/credit_generation_cooldown

/obj/machinery/rnd/proc/reset_busy()
	busy = FALSE

/obj/machinery/rnd/Initialize(mapload)
	..()
	stored_research = SSresearch.science_tech
	wires = new /datum/wires/rnd(src)
	if(isnull(bank_account))
		bank_account = new
		bank_account.account_balance = MAX_MATERIAL_REWARD

	return INITIALIZE_HINT_LATELOAD

/obj/machinery/rnd/LateInitialize()
	. = ..()

	var/datum/component/material_container/material_container = GetComponent(/datum/component/material_container)
	material_container?.after_insert = CALLBACK(src, .proc/PayAfterMaterialInsert)

/obj/machinery/rnd/Destroy()
	stored_research = null
	QDEL_NULL(wires)
	return ..()

/obj/machinery/rnd/proc/shock(mob/user, prb)
	if(machine_stat & (BROKEN|NOPOWER)) // unpowered, no shock
		return FALSE
	if(!prob(prb))
		return FALSE
	do_sparks(5, TRUE, src)
	if (electrocute_mob(user, get_area(src), src, 0.7, TRUE))
		return TRUE
	else
		return FALSE

/obj/machinery/rnd/attackby(obj/item/O, mob/user, params)
	if(is_refillable() && O.is_drainable() && O.reagents.total_volume)
		return FALSE //inserting reagents into the machine
	if(Insert_Item(O, user))
		return TRUE

	return ..()

/obj/machinery/rnd/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(tool)

/obj/machinery/rnd/crowbar_act_secondary(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(tool)

/obj/machinery/rnd/screwdriver_act(mob/living/user, obj/item/tool)
	return default_deconstruction_screwdriver(user, "[initial(icon_state)]_t", initial(icon_state), tool)

/obj/machinery/rnd/screwdriver_act_secondary(mob/living/user, obj/item/tool)
	return default_deconstruction_screwdriver(user, "[initial(icon_state)]_t", initial(icon_state), tool)

/obj/machinery/rnd/multitool_act(mob/living/user, obj/item/tool)
	if(panel_open)
		wires.interact(user)
		return TRUE

/obj/machinery/rnd/multitool_act_secondary(mob/living/user, obj/item/tool)
	if(panel_open)
		wires.interact(user)
		return TRUE

/obj/machinery/rnd/wirecutter_act(mob/living/user, obj/item/tool)
	if(panel_open)
		wires.interact(user)
		return TRUE

/obj/machinery/rnd/wirecutter_act_secondary(mob/living/user, obj/item/tool)
	if(panel_open)
		wires.interact(user)
		return TRUE

//proc used to handle inserting items or reagents into rnd machines
/obj/machinery/rnd/proc/Insert_Item(obj/item/I, mob/user)
	return

//whether the machine can have an item inserted in its current state.
/obj/machinery/rnd/proc/is_insertion_ready(mob/user)
	if(panel_open)
		to_chat(user, span_warning("You can't load [src] while it's opened!"))
		return FALSE
	if(disabled)
		to_chat(user, span_warning("The insertion belts of [src] won't engage!"))
		return FALSE
	if(busy)
		to_chat(user, span_warning("[src] is busy right now."))
		return FALSE
	if(machine_stat & BROKEN)
		to_chat(user, span_warning("[src] is broken."))
		return FALSE
	if(machine_stat & NOPOWER)
		to_chat(user, span_warning("[src] has no power."))
		return FALSE
	if(loaded_item)
		to_chat(user, span_warning("[src] is already loaded."))
		return FALSE
	return TRUE

//we eject the loaded item when deconstructing the machine
/obj/machinery/rnd/on_deconstruction()
	if(loaded_item)
		loaded_item.forceMove(loc)
	..()

/obj/machinery/rnd/proc/AfterMaterialInsert(item_inserted, id_inserted, amount_inserted)
	var/stack_name
	if(istype(item_inserted, /obj/item/stack/ore/bluespace_crystal))
		stack_name = "bluespace"
		use_power(MINERAL_MATERIAL_AMOUNT / 10)
	else
		var/obj/item/stack/S = item_inserted
		stack_name = S.name
		use_power(min(1000, (amount_inserted / 100)))
	add_overlay("protolathe_[stack_name]")
	addtimer(CALLBACK(src, /atom/proc/cut_overlay, "protolathe_[stack_name]"), 10)

/obj/machinery/rnd/process()
	if(bank_account.account_balance >= MAX_MATERIAL_REWARD || credit_generation_cooldown >= world.time)
		return
	credit_generation_cooldown = world.time + CREDIT_COOLDOWN_LENGTH
	bank_account.account_balance = min(MAX_MATERIAL_REWARD, bank_account.account_balance + 5)
	to_chat(world, "[src] account_balance is now [bank_account.account_balance].")

/obj/machinery/rnd/proc/PayAfterMaterialInsert(item_inserted, id_inserted, amount_inserted, last_inserted_list, mob/living/user)
	if(!length(last_inserted_list) || isstack(item_inserted))
		return
	var/obj/item/card/id/card = user.get_idcard(TRUE)
	if (!card || !card.registered_account)
		return
	var/reward = 0
	for(var/datum/material/material in last_inserted_list)
		reward += last_inserted_list[material] * material.value_per_unit
	reward = min(bank_account.account_balance, round(reward))
	if(!reward)
		return
	card.registered_account.transfer_money(bank_account, reward)
	card.registered_account.bank_card_talk("[reward] credit\s added to your account for recycled materials.")

#undef MAX_MATERIAL_REWARD
#undef CREDIT_COOLDOWN_LENGTH
