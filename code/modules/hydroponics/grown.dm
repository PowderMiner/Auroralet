//Grown foods.
/obj/item/reagent_containers/food/snacks/grown

	name = "fruit"
	icon = 'icons/obj/hydroponics_products.dmi'
	icon_state = "blank"
	desc = "Nutritious! Probably."
	slot_flags = SLOT_HOLSTER
	drop_sound = 'sound/items/drop/herb.ogg'
	pickup_sound = 'sound/items/pickup/herb.ogg'

	storage_slot_sort_by_name = TRUE
	var/plantname
	var/datum/seed/seed
	var/potency = -1

/obj/item/reagent_containers/food/snacks/grown/Initialize(loca, planttype)
	. = ..()
	if(!dried_type)
		dried_type = type
	src.pixel_x = rand(-5.0, 5)
	src.pixel_y = rand(-5.0, 5)

	// Fill the object up with the appropriate reagents.
	if(planttype)
		plantname = planttype

	if(!plantname)
		return

	if(!SSplants)
		to_world(SPAN_DANGER("Plant controller does not exist and [src] requires it. Aborting."))
		qdel(src)
		return

	seed = SSplants.seeds[plantname]

	if(!seed)
		return

	name = "[seed.seed_name]"
	trash = seed.get_trash_type()

	update_icon()

	if(!seed.chems)
		return

	potency = seed.get_trait(TRAIT_POTENCY)

	for(var/rid in seed.chems)
		var/list/reagent_data = seed.chems[rid]
		if(reagent_data && reagent_data.len)
			var/rtotal = reagent_data[1]
			var/list/data = list()
			if(reagent_data.len > 1 && potency > 0)
				rtotal += round(potency/reagent_data[2])
			if(rid == /singleton/reagent/nutriment)
				data[seed.seed_name] = max(1,rtotal)
			reagents.add_reagent(rid,max(1,rtotal),data)
	update_desc()
	if(reagents.total_volume > 0)
		bitesize = 1+round(reagents.total_volume / 2, 1)

	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)

	AddElement(/datum/element/connect_loc, loc_connections)

/obj/item/reagent_containers/food/snacks/grown/proc/update_desc()

	if(!seed)
		return
	if(!SSplants)
		to_world(SPAN_DANGER("Plant controller does not exist and [src] requires it. Aborting."))
		qdel(src)
		return

	if(SSplants.product_descs["[seed.uid]"])
		desc = SSplants.product_descs["[seed.uid]"]
	else
		var/list/descriptors = list()
		if(reagents.has_reagent(/singleton/reagent/sugar) || reagents.has_reagent(/singleton/reagent/nutriment/cherryjelly) || reagents.has_reagent(/singleton/reagent/nutriment/honey) || reagents.has_reagent(/singleton/reagent/drink/berryjuice))
			descriptors |= "sweet"
		if(reagents.has_reagent(/singleton/reagent/dylovene))
			descriptors |= "astringent"
		if(reagents.has_reagent(/singleton/reagent/frostoil))
			descriptors |= "numbing"
		if(reagents.has_reagent(/singleton/reagent/nutriment))
			descriptors |= "nutritious"
		if(reagents.has_reagent(/singleton/reagent/capsaicin/condensed) || reagents.has_reagent(/singleton/reagent/capsaicin))
			descriptors |= "spicy"
		if(reagents.has_reagent(/singleton/reagent/nutriment/coco))
			descriptors |= "bitter"
		if(reagents.has_reagent(/singleton/reagent/drink/orangejuice) || reagents.has_reagent(/singleton/reagent/drink/lemonjuice) || reagents.has_reagent(/singleton/reagent/drink/limejuice))
			descriptors |= "sweet-sour"
		if(reagents.has_reagent(/singleton/reagent/radium) || reagents.has_reagent(/singleton/reagent/uranium))
			descriptors |= "radioactive"
		if(reagents.has_reagent(/singleton/reagent/toxin/amatoxin) || reagents.has_reagent(/singleton/reagent/toxin))
			descriptors |= "poisonous"
		if(reagents.has_reagent(/singleton/reagent/drugs/psilocybin) || reagents.has_reagent(/singleton/reagent/drugs/ambrosia_extract) || reagents.has_reagent(/singleton/reagent/drugs/mms) || reagents.has_reagent(/singleton/reagent/drugs/mindbreaker))
			descriptors |= "hallucinogenic"
		if(reagents.has_reagent(/singleton/reagent/bicaridine) || reagents.has_reagent(/singleton/reagent/dylovene))
			descriptors |= "medicinal"
		if(reagents.has_reagent(/singleton/reagent/gold))
			descriptors |= "shiny"
		if(reagents.has_reagent(/singleton/reagent/lube))
			descriptors |= "slippery"
		if(reagents.has_reagent(/singleton/reagent/acid/polyacid) || reagents.has_reagent(/singleton/reagent/acid) || reagents.has_reagent(/singleton/reagent/acid/hydrochloric))
			descriptors |= "acidic"
		if(seed.get_trait(TRAIT_JUICY))
			descriptors |= "juicy"
		if(seed.get_trait(TRAIT_STINGS))
			descriptors |= "stinging"
		if(seed.get_trait(TRAIT_TELEPORTING))
			descriptors |= "glowing"
		if(seed.get_trait(TRAIT_EXPLOSIVE))
			descriptors |= "bulbous"

		var/descriptor_num = rand(2,4)
		var/descriptor_count = descriptor_num
		desc = "A"
		while(descriptors.len && descriptor_num > 0)
			var/chosen = pick(descriptors)
			descriptors -= chosen
			desc += "[(descriptor_count>1 && descriptor_count!=descriptor_num) ? "," : "" ] [chosen]"
			descriptor_num--
		if(seed.seed_noun == SEED_NOUN_SPORES)
			desc += " mushroom"
		else
			desc += " fruit"
		SSplants.product_descs["[seed.uid]"] = desc
	desc += ". Delicious! Probably."

/obj/item/reagent_containers/food/snacks/grown/update_icon()
	if(!seed || !SSplants || !SSplants.plant_icon_cache)
		return
	ClearOverlays()
	var/image/plant_icon
	var/icon_key = "fruit-[seed.get_trait(TRAIT_PRODUCT_ICON)]-[seed.get_trait(TRAIT_PRODUCT_COLOUR)]-[seed.get_trait(TRAIT_PLANT_COLOUR)]"
	if(SSplants.plant_icon_cache[icon_key])
		plant_icon = SSplants.plant_icon_cache[icon_key]
	else
		plant_icon = image('icons/obj/hydroponics_products.dmi',"blank")
		var/image/fruit_base = image('icons/obj/hydroponics_products.dmi',"[seed.get_trait(TRAIT_PRODUCT_ICON)]-product")
		fruit_base.color = "[seed.get_trait(TRAIT_PRODUCT_COLOUR)]"
		plant_icon.overlays |= fruit_base
		if("[seed.get_trait(TRAIT_PRODUCT_ICON)]-leaf" in icon_states('icons/obj/hydroponics_products.dmi'))
			var/image/fruit_leaves = image('icons/obj/hydroponics_products.dmi',"[seed.get_trait(TRAIT_PRODUCT_ICON)]-leaf")
			fruit_leaves.color = "[seed.get_trait(TRAIT_PLANT_COLOUR)]"
			plant_icon.overlays |= fruit_leaves
		SSplants.plant_icon_cache[icon_key] = plant_icon
	AddOverlays(plant_icon)

/obj/item/reagent_containers/food/snacks/grown/proc/on_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	if(seed && seed.get_trait(TRAIT_JUICY) == 2)
		if(isliving(arrived))
			var/mob/living/M = arrived

			if(M.buckled_to)
				return

			if(istype(M,/mob/living/carbon/human))
				var/mob/living/carbon/human/H = M
				if(H.shoes && H.shoes.item_flags & ITEM_FLAG_NO_SLIP)
					return

			M.stop_pulling()
			to_chat(M, SPAN_NOTICE("You slipped on the [name]!"))
			playsound(src.loc, 'sound/misc/slip.ogg', 50, 1, -3)
			M.Stun(8)
			M.Weaken(5)
			seed.thrown_at(src,M)
			if(src) qdel(src)
			return

/obj/item/reagent_containers/food/snacks/grown/throw_impact(atom/hit_atom)
	if(seed) seed.thrown_at(src,hit_atom)
	..()

/obj/item/reagent_containers/food/snacks/grown/attackby(obj/item/attacking_item, mob/user)

	if(istype(attacking_item, /obj/item/paper))
		if(!dry)
			to_chat(user, SPAN_WARNING("You need to dry \the [src] first!"))
			return
		if(user.unEquip(attacking_item))
			var/obj/item/clothing/mask/smokable/cigarette/rolled/R = new(get_turf(src))
			R.chem_volume = reagents.total_volume
			reagents.trans_to_holder(R.reagents, R.chem_volume)
			user.visible_message(SPAN_NOTICE("[user] rolls a cigarette in their hands with \the [attacking_item] and [src]."),
								SPAN_NOTICE("You roll a cigarette in your hands with \the [attacking_item] and [src]."))
			playsound(src, 'sound/bureaucracy/paperfold.ogg', 25, 1)
			user.put_in_active_hand(R)
			qdel(attacking_item)
			qdel(src)
			return

	if(seed)
		if(seed.get_trait(TRAIT_PRODUCES_POWER) && attacking_item.iscoil())
			var/obj/item/stack/cable_coil/C = attacking_item
			if(C.use(5))
				//TODO: generalize this.
				to_chat(user, SPAN_NOTICE("You add some cable to the [src.name] and slide it inside the battery casing."))
				var/obj/item/cell/potato/pocell = new /obj/item/cell/potato(get_turf(user))
				if(src.loc == user && !(user.l_hand && user.r_hand) && istype(user,/mob/living/carbon/human))
					user.put_in_hands(pocell)
				pocell.maxcharge = src.potency * 10
				pocell.charge = pocell.maxcharge
				qdel(src)
				return
		else if(attacking_item.sharp && !attacking_item.noslice)
			if(seed.kitchen_tag == "pumpkin") // Ugggh these checks are awful.
				user.show_message(SPAN_NOTICE("You carve a face into [src]!"), 1)
				user.put_in_hands(new /obj/item/clothing/head/pumpkin)
				qdel(src)
				return
			else if(seed.chems)
				if(istype(attacking_item,/obj/item/material/hatchet) && !isnull(seed.chems[/singleton/reagent/woodpulp]))
					user.show_message(SPAN_NOTICE("You make planks out of \the [src]!"), 1)
					playsound(loc, 'sound/effects/woodcutting.ogg', 50, 1)
					var/flesh_colour = seed.get_trait(TRAIT_FLESH_COLOUR)
					if(!flesh_colour) flesh_colour = seed.get_trait(TRAIT_PRODUCT_COLOUR)
					for(var/i=0,i<2,i++)
						var/obj/item/stack/material/wood/NG = new (user.loc)
						if(flesh_colour) NG.color = flesh_colour
						for (var/obj/item/stack/material/wood/G in user.loc)
							if(G==NG)
								continue
							if(G.amount>=G.max_amount)
								continue
							G.attackby(NG, user)
						to_chat(user, "You add the newly-formed wood to the stack. It now contains [NG.amount] planks.")
					qdel(src)
					return
				else if(!isnull(seed.chems[/singleton/reagent/drink/potatojuice]))
					to_chat(user, "You slice \the [src] into sticks.")
					new /obj/item/reagent_containers/food/snacks/rawsticks(get_turf(src))
					qdel(src)
					return
				else if(!isnull(seed.chems[/singleton/reagent/drink/carrotjuice]))
					to_chat(user, "You slice \the [src] into sticks.")
					new /obj/item/reagent_containers/food/snacks/carrotfries(get_turf(src))
					qdel(src)
					return
				else if(!isnull(seed.chems[/singleton/reagent/drink/earthenrootjuice]))
					to_chat(user, "You slice \the [src] into sticks.")
					new /obj/item/reagent_containers/food/snacks/earthenroot_chopped(get_turf(src))
					qdel(src)
					return
				else if(!isnull(seed.chems[/singleton/reagent/drink/milk/soymilk]))
					to_chat(user, "You roughly chop up \the [src].")
					new /obj/item/reagent_containers/food/snacks/soydope(get_turf(src))
					qdel(src)
					return
				else if(seed.get_trait(TRAIT_FLESH_COLOUR))
					if (reagents.total_volume)
						to_chat(user, "You slice up \the [src].")
						var/slices = rand(3,5)
						var/reagents_to_transfer = reagents.total_volume/slices
						for(var/i=0;i<slices;i++)
							var/obj/item/reagent_containers/food/snacks/fruit_slice/F = new(get_turf(src),seed)
							reagents.trans_to_obj(F,reagents_to_transfer)
							if(dry)
								F.on_dry()
						qdel(src)
						return
	..()

/obj/item/reagent_containers/food/snacks/grown/apply_hit_effect(mob/living/target, mob/living/user, var/hit_zone)
	. = ..()

	if(seed && seed.get_trait(TRAIT_STINGS))
		if(!reagents || reagents.total_volume <= 0)
			return
		reagents.remove_any(rand(1,3))
		seed.thrown_at(src, target)
		sleep(-1)
		if(!src)
			return
		if(prob(35))
			if(user)
				to_chat(user, SPAN_DANGER("\The [src] has fallen to bits."))
			qdel(src)

/obj/item/reagent_containers/food/snacks/grown/attack_self(mob/user as mob)

	if(!seed)
		return

	if(istype(user.loc,/turf/space))
		return

	if(user.a_intent == I_HURT)
		user.visible_message(SPAN_DANGER("\The [user] squashes \the [src]!"))
		seed.thrown_at(src,user)
		sleep(-1)
		if(src) qdel(src)
		return

	if(seed.kitchen_tag == "grass")
		user.show_message(SPAN_NOTICE("You make a grass tile out of \the [src]!"), 1)
		var/flesh_colour = seed.get_trait(TRAIT_FLESH_COLOUR)
		if(!flesh_colour) flesh_colour = seed.get_trait(TRAIT_PRODUCT_COLOUR)
		for(var/i=0,i<2,i++)
			var/obj/item/stack/tile/grass/G = new (user.loc)
			if(flesh_colour) G.color = flesh_colour
			for (var/obj/item/stack/tile/grass/NG in user.loc)
				if(G==NG)
					continue
				if(NG.amount>=NG.max_amount)
					continue
				NG.attackby(G, user)
			to_chat(user, "You add the newly-formed grass to the stack. It now contains [G.amount] tiles.")
		user.drop_from_inventory(src)
		qdel(src)
		return

	if(seed.get_trait(TRAIT_SPREAD) > 0)
		to_chat(user, SPAN_NOTICE("You plant the [src.name]."))
		new /obj/machinery/portable_atmospherics/hydroponics/soil/invisible(get_turf(user),src.seed)
		qdel(src)
		return

	/*
	if(seed.kitchen_tag)
		switch(seed.kitchen_tag)
			if("shand")
				var/obj/item/stack/medical/bruise_pack/tajaran/poultice = new /obj/item/stack/medical/bruise_pack/tajaran(user.loc)
				poultice.heal_brute = potency
				to_chat(user, SPAN_NOTICE("You mash the leaves into a poultice."))
				qdel(src)
				return
			if("mtear")
				var/obj/item/stack/medical/ointment/tajaran/poultice = new /obj/item/stack/medical/ointment/tajaran(user.loc)
				poultice.heal_burn = potency
				to_chat(user, SPAN_NOTICE("You mash the petals into a poultice."))
				qdel(src)
				return
	*/

/obj/item/reagent_containers/food/snacks/grown/pickup(mob/user)
	..()
	if(!seed)
		return
	if(seed.get_trait(TRAIT_STINGS))
		var/mob/living/carbon/human/H = user
		if(istype(H) && H.gloves)
			return
		if(!reagents || reagents.total_volume <= 0)
			return
		reagents.remove_any(rand(1,3)) //Todo, make it actually remove the reagents the seed uses.
		seed.do_thorns(H,src)
		seed.do_sting(H,src,pick(BP_R_HAND,BP_L_HAND))

/obj/item/reagent_containers/food/snacks/fruit_slice
	name = "fruit slice"
	desc = "A slice of some tasty fruit."
	icon = 'icons/obj/hydroponics_misc.dmi'
	icon_state = ""
	drop_sound = 'sound/items/drop/herb.ogg'
	pickup_sound = 'sound/items/pickup/herb.ogg'
	dried_type = /obj/item/reagent_containers/food/snacks/fruit_slice
	var/datum/seed/seed

GLOBAL_LIST_EMPTY(fruit_icon_cache)

/obj/item/reagent_containers/food/snacks/fruit_slice/Initialize(mapload, datum/seed/S)
	. = ..()
	// Need to go through and make a general image caching controller. Todo.
	if(!istype(S))
		qdel(src)
		return

	name = "[S.seed_name] slice"
	desc = "A slice of \a [S.seed_name]. Tasty, probably."
	seed = S

	var/rind_colour = seed.get_trait(TRAIT_PRODUCT_COLOUR)
	var/flesh_colour = seed.get_trait(TRAIT_FLESH_COLOUR)
	if(!flesh_colour) flesh_colour = rind_colour
	if(!GLOB.fruit_icon_cache["rind-[rind_colour]"])
		var/image/I = image(icon,"fruit_rind")
		I.color = rind_colour
		GLOB.fruit_icon_cache["rind-[rind_colour]"] = I
	AddOverlays(GLOB.fruit_icon_cache["rind-[rind_colour]"])
	if(!GLOB.fruit_icon_cache["slice-[rind_colour]"])
		var/image/I = image(icon,"fruit_slice")
		I.color = flesh_colour
		GLOB.fruit_icon_cache["slice-[rind_colour]"] = I
	AddOverlays(GLOB.fruit_icon_cache["slice-[rind_colour]"])

/obj/item/reagent_containers/food/snacks/grown/konyang_tea
	name = "sencha leaves"
	desc = "A type of green tea originating from Japan on Earth, sencha is unique in that it is steamed instead of pan-roasted like most teas. \
			It has a fresh flavor profile as a result, with flavors like seaweed, grass, or spinach greens predominant. On Konyang, it is most popular in Aoyama."
	plantname = "sencha"
	icon = 'icons/obj/item/reagent_containers/teaware.dmi'
	icon_state = "sencha"

/obj/item/reagent_containers/food/snacks/grown/konyang_tea/update_desc()
	return

/obj/item/reagent_containers/food/snacks/grown/konyang_tea/afterattack(atom/target, mob/user, proximity, params)
	if(proximity && target.is_open_container() && target.reagents)
		if(!target.reagents.total_volume)
			to_chat(user, SPAN_WARNING("You can't steep tea inside of an empty pot!"))
			return
		to_chat(user, SPAN_NOTICE("You steep \the [src] inside \the [target]."))

		reagents.trans_to(target, reagents.total_volume)
		qdel(src)

/obj/item/reagent_containers/food/snacks/grown/konyang_tea/tieguanyin
	name = "tieguanyin leaves"
	desc = "A type of oolong tea originating from China on Earth. Like most oolongs, its flavor is somewhere between green and black tea. \
			It has a nutty, peppery, and floral flavor profile. On Konyang, it is most popular in Ganzaodeng and New Hong Kong."
	plantname = "tieguanyin"
	icon_state = "tieguanyin"

/obj/item/reagent_containers/food/snacks/grown/konyang_tea/jaekseol
	name = "jaekseol leaves"
	desc = "A type of black tea originating from Korea on Earth. It has a relatively typical flavor for a black tea, with a sweet, toasty flavor. \
			On Konyang, it is most popular in Suwon, although coffee is still a more popular beverage in general."
	plantname = "jaekseol"
	icon_state = "jaekseol"
