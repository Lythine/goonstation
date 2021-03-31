/////////////////////// debris field pod stuff

/obj/item/taxipodengine
	name = "Taxi Pod Engine"
	desc = "An engine specifically for use in taxi pods. It's in pretty good condition."
	icon = 'icons/obj/ship.dmi'
	icon_state = "engine-4"

/obj/item/taxipodengine/rusty
	name = "Rusty Taxi Pod Engine"
	desc = "An engine specifically for use in taxi pods. It's very rusty."
	icon = 'icons/obj/ship.dmi'
	icon_state = "engine-4"

/obj/structure/brokentaxipod
	name = "Broken Taxi Pod"
	desc = "A small one-person pod that appears to automatically take whoever's in it somewhere. These must've gone out of use years ago. Seems like it could use some new parts."
	icon = 'icons/obj/ship.dmi'
	icon_state = "escape"
	anchored = 1
	dir = 4

	attackby(obj/item/W as obj, mob/living/user as mob)
		var/obj/item/taxipodengine/C = W
		if (istype(C))
			boutput(user, "You replace the pod's rusty engine.")
			new /obj/machinery/vehicle/escape_pod/taxipod(src.loc)
			new /obj/item/taxipodengine/rusty(src.loc)
			user.u_equip(W)
			qdel(W)
			qdel(src)

/obj/machinery/vehicle/escape_pod/taxipod
	name = "Taxi Pod V-"
	desc = "A small one-person pod that appears to automatically take whoever's in it somewhere. These must've gone out of use years ago."
	icon = 'icons/obj/ship.dmi'
	icon_state = "escape"
	capacity = 1
	health = 100
	maxhealth = 100
	speed = 5
	anchored = 1
	dir = 4 // todo: not this
	var/target = null // goes to the pod entry location (in space vegas)

	New()
		..()
		SPAWN_DBG(1 DECI SECOND)
			for(var/obj/adventurepuzzle/invisible/target_link/T)
				if (T.id == "SV-POD-ENTRY-ZONE")
					target = get_turf(T)
					return

	finish_board_pod(var/mob/boarder)
		..()
		if (!src.pilot) return
		SPAWN_DBG(0)
			playsound(get_turf(src), "sound/misc/belt_click.ogg", 50, 1)
			boarder.show_text("A seatbelt automatically buckles you to the seat of the pod!", "red")
			src.escape()

	exit_ship()
		if (is_incapacitated(usr))
			usr.show_text("Not when you're incapacitated.", "red")
			return

		usr.show_text("You're unable to take off your seatbelt!", "red")
		return

	escape()
		if(!launched)
			launched = 1
			anchored = 0
			var/opened_door = 0
			var/turf_in_front = get_step(src,src.dir)

			for(var/obj/machinery/door/poddoor/D in turf_in_front) // open the door
				D.open()
				opened_door = 1
			if(opened_door) sleep(2 SECONDS) // make sure it's fully open

			var/obj/warp_portal/P = new /obj/warp_portal( src.loc ) // make a portal
			P.transform = matrix(0, MATRIX_SCALE)
			for(var/i=0, i<2, i++)
				step(P, src.dir)
			var/dist = get_dist(src, P)
			P.pixel_x = -dist*32
			animate(P, transform = matrix(1, MATRIX_SCALE), pixel_x = 0, pixel_y = 0, time = 30, easing = ELASTIC_EASING )
			sleep(30)
			P.target = target // make it go to space vegas
			logTheThing("station", usr, null, "creates a wormhole to space vegas.")

			playsound(src.loc, "sound/effects/bamf.ogg", 100, 0)
			sleep(0.5 SECONDS)
			playsound(src.loc, "sound/effects/flameswoosh.ogg", 100, 0)

			while(!failing)
				var/loc = src.loc
				step(src,src.dir)
				if(src.loc == loc) // we hit something
					var/obj/hit = get_step(src,src.dir)
					if (istype(hit, /turf/cordon))
						qdel(src)
						break
					else if (hit != P)
						explosion(src, src.loc, 1, 1, 2, 3)
						fail()
						break
				sleep(0.4 SECONDS)

	succeed() // we don't need this
		return

	fail()
		failing = 1
		shipdeath() // who cares just kill it



/obj/trigger/poddropoff
	name = "pod drop off trigger"
	desc = "makes pods drop all of their occupants off"

	on_trigger(atom/movable/triggerer)
		var/obj/machinery/vehicle/P = triggerer
		if(!istype(P))
			return
		while(P.passengers > 0)
			P.pilot.set_loc(P.loc) // set_loc calls eject on the pod


//////////////////////////////// inside of space vegas

/obj/decal/fakeobjects/kitchenspikehuman
	name = "a meat spike"
	desc = "You can't make out if there's a monkey or a human on there..."
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "spikebloody"
