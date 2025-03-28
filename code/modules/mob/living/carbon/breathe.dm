//Common breathing procs

//Start of a breath chain, calls breathe()
/mob/living/carbon/handle_breathing()
	if(SSair.times_fired%4==2 || failed_last_breath || is_asystole()) 	//First, resolve location and get a breath
		breathe()

/mob/living/carbon/proc/inhale(var/datum/reagents/from, var/datum/reagents/target, var/amount = 1, var/multiplier = 1, var/copy = 0, var/bypass_checks = FALSE)

	if(species && (species.flags & NO_BREATHE)) //Check for species
		return 0

	if(!bypass_checks)

		if(wear_mask && wear_mask.item_flags & ITEM_FLAG_BLOCK_GAS_SMOKE_EFFECT) //Check if the gasmask blocks an effect
			return 0

		if (internals && internals.icon_state == "internal1") //Check for internals
			return 0

	return from.trans_to_holder(target,amount,multiplier,copy) //complete transfer

/mob/living/carbon/proc/breathe(var/volume_needed = BREATH_VOLUME)
	if(species && (species.flags & NO_BREATHE))
		return
	if(HAS_TRAIT(src, TRAIT_PRESSURE_IMMUNITY))
		return

	volume_needed *= (species?.breath_vol_mul || 1)

	var/datum/gas_mixture/breath = null

	//First, check if we can breathe at all
	if(is_asystole() && !(CE_STABLE in chem_effects)) //crit aka circulatory shock
		losebreath = max(2, losebreath + 1)

	if(losebreath>0) //Suffocating so do not take a breath
		losebreath--
		if (prob(10) && !isipc(src) && !is_asystole()) //Gasp per 10 ticks? Sounds about right.
			emote("gasp")
	else
		//Okay, we can breathe, now check if we can get air
		breath = get_breath_from_internal(volume_needed) //First, check for air from internals
		if(!breath)
			breath = get_breath_from_environment(volume_needed) //No breath from internals so let's try to get air from our location

	handle_breath(breath)
	handle_post_breath(breath)

/mob/living/carbon/proc/get_breath_from_internal(var/volume_needed=BREATH_VOLUME) //hopefully this will allow overrides to specify a different default volume without breaking any cases where volume is passed in.
	if(internal)
		if (!contents.Find(internal))
			internal = null
		if (!(wear_mask && (wear_mask.item_flags & ITEM_FLAG_AIRTIGHT)))
			internal = null
		if(internal)
			if (internals)
				internals.icon_state = "internal1"
			return internal.remove_air_volume(volume_needed)
		else
			if (internals)
				internals.icon_state = "internal0"
	return null

/mob/living/carbon/proc/get_breath_from_environment(var/volume_needed=BREATH_VOLUME)
	var/datum/gas_mixture/breath = null

	var/datum/gas_mixture/environment
	if(loc)
		environment = loc.return_air_for_internal_lifeform(src)

	if(environment)
		breath = environment.remove_volume(volume_needed)
		handle_chemical_smoke(environment) //handle chemical smoke while we're at it

	if(breath && breath.total_moles)
		//handle mask filtering
		if(istype(wear_mask, /obj/item/clothing/mask) && breath)
			var/obj/item/clothing/mask/M = wear_mask
			var/datum/gas_mixture/filtered = M.filter_air(breath)
			loc.assume_air(filtered)
		return breath
	return null

//Handle possble chem smoke effect
/mob/living/carbon/proc/handle_chemical_smoke(var/datum/gas_mixture/environment)
	if(species && environment.return_pressure() < species.breath_pressure/5)
		return //pressure is too low to even breathe in.
	if(wear_mask && (wear_mask.item_flags & ITEM_FLAG_BLOCK_GAS_SMOKE_EFFECT))
		return

	for(var/obj/effect/smoke/chem/smoke in view(1, src))
		if(smoke.reagents.total_volume)
			smoke.reagents.trans_to_mob(src, 5, CHEM_INGEST, copy = 1)
			smoke.reagents.trans_to_mob(src, 5, CHEM_TOUCH, copy = 1)
			smoke.reagents.trans_to_mob(src, 5, CHEM_BREATHE, copy = 1)
			// I dunno, maybe the reagents enter the blood stream through the lungs?
			// ^ HA HA HA HA
			break

/mob/living/carbon/proc/handle_breath(datum/gas_mixture/breath)
	return

/mob/living/carbon/proc/handle_post_breath(datum/gas_mixture/breath)
	if(!breath)
		return
	loc.assume_air(breath) //exhale into the environment
