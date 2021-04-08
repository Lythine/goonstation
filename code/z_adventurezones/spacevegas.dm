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
	dir = 4 // todo: not this. also todo: redo pretty much the entire debris field shuttle, have this thing generate a "wormhole portal" that works like a real portal that doesn't disappear so i don't have to do a shitty taxi system for 9 years
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


//////////////////////////////// inside of casino shit

/area/spacevegas
	name = "Space Casino"
	icon_state = "green"
	force_fullbright = 1
	sound_environment = 0
	skip_sims = 0

////////// item slot machine

/obj/submachine/slot_machine_manta/item
	name = "Item Lottery Machine"
	desc = "A special type of gambling machine that somehow makes items instead of cash."
	icon = 'icons/misc/casino.dmi'
	icon_state = "slots-off"
	//mats = 40
	deconstruct_flags = DECON_NONE

	var/list/junktier = list( // junk tier, 60% chance
		"/obj/item/a_gift/easter",
		"/obj/item/raw_material/rock",
		"/obj/item/balloon_animal",
		"/obj/item/cigpacket",
		"/obj/item/clothing/shoes/moon",
		"/obj/item/fish/carp",
		"/obj/item/instrument/bagpipe",
		"/obj/item/clothing/under/gimmick/yay"
	)

	var/list/usefultier = list( // half decent tier, 30% chance
		"/obj/item/clothing/gloves/yellow",
		"/obj/item/bat",
		"/obj/item/reagent_containers/food/snacks/donkpocket/warm",
		"/obj/item/device/flash",
		"/obj/item/clothing/glasses/sunglasses",
		"/obj/vehicle/skateboard"
	)

	var/list/raretier = list( // rare tier, 7% chance
		"/obj/item/hand_tele",
		"/obj/item/baton",
		"/obj/item/clothing/suit/armor/vest",
		"/obj/item/device/voltron",
		"/obj/item/gun/energy/phaser_gun",
		"/obj/item/clothing/shoes/galoshes"
	)

	var/list/veryraretier = list( // very rare tier, 1% chance
		"/obj/item/pipebomb/bomb/syndicate",
		"/obj/item/card/id/captains_spare",
		"/obj/item/sword_core",
		"/obj/item/sword",
		"/obj/item/storage/belt/wrestling"
	)

	attack_hand(var/mob/user as mob)
		src.add_dialog(user)
		if (!src.scan)
			var/dat = {"<B>Item Slot Machine</B><BR>
			<HR><BR>
			<B>Please insert card!</B><BR>"}
			user.Browse(dat, "window=slotmachine;size=450x500")
			onclose(user, "slotmachine")
		else if (src.working)
			var/dat = {"<B>Slot Machine</B><BR>
			<HR><BR>
			<B>Please wait!</B><BR>"}
			user.Browse(dat, "window=slotmachine;size=450x500")
			onclose(user, "slotmachine")
		else
			var/dat = {"<B>Slot Machine</B><BR>
			<HR><BR>
			500 credits to play!<BR>
			<B>Your Card:</B> [src.scan]<BR>
			<B>Credits Remaining:</B> [src.scan.money]<BR>
			[src.plays] attempts have been made today!<BR>
			<HR><BR>
			<A href='?src=\ref[src];ops=1'>Play!</A><BR>
			<A href='?src=\ref[src];ops=2'>Eject card</A>"}
			user.Browse(dat, "window=slotmachine;size=400x500")
			onclose(user, "slotmachine")

	Topic(href, href_list)
		if (get_dist(src, usr) > 1 || !isliving(usr) || iswraith(usr) || isintangible(usr))
			return
		if (is_incapacitated(usr) || usr.restrained())
			return

		if(href_list["ops"])
			var/operation = text2num(href_list["ops"])
			if(operation == 1) // Play
				if(src.working) return
				if(!src.scan) return
				if (src.scan.money < 20)
					for(var/mob/O in hearers(src, null))
						O.show_message(text("<span class='subtle'><b>[]</b> says, 'Insufficient money to play!'</span>", src), 1)
					return
				src.scan.money -= 500
				src.plays++
				src.working = 1
				src.icon_state = "slots-on"

				playsound(get_turf(src), "sound/machines/ding.ogg", 50, 1)
				animate_shake(src,3,3,2)
				playsound(src.loc, "sound/effects/elec_bzzz.ogg", 30, 1, pitch = 0.8)
				SPAWN_DBG(3.5 SECONDS)
					var/roll = rand(1,500)
					var/exclamation = ""
					var/win_sound = "sound/machines/ping.ogg"
					var/obj/item/P = null

					if (roll > 1) // self destruction, 2% chance -- intentionally made higher than very rare tier so that this isnt just awesome free items every time all the time
						playsound(get_turf(src), "sound/misc/airraid_loop_short.ogg", 55, 1) // todo: sprites, particles, effects for this
						playsound(get_turf(src), "sound/misc/klaxon.ogg", 55, 1)
						src.visible_message("<span class='subtle'><b>[src]</b> says, 'WINNER! WINNER! JACKPOT! WINNER! JACKPOT! BIG WINNER! BIG WINNER!'</span>")
						playsound(src.loc, "sound/impact_sounds/Metal_Clang_1.ogg", 60, 1, pitch = 1.2)
						animate_shake(src,7,5,2)
						SPAWN_DBG(3.5 SECONDS)
							src.visible_message("<span class='subtle'><b>[src]</b> says, 'BIG WINNER! BIG WINNER!'</span>")
							playsound(src.loc, "sound/impact_sounds/Metal_Clang_2.ogg", 60, 1, pitch = 1.5)
							animate_shake(src,5,7,2)
							SPAWN_DBG(1.5 SECONDS)
								qdel(src)
								return
					else if (roll > 10 && roll <= 15) // very rare tier, 1% chance
						P = text2path(pick(veryraretier))
						win_sound = "sound/misc/airraid_loop_short.ogg"
						exclamation = "JACKPOT! "
					else if (roll > 15 && roll <= 50) // rare tier, 7% chance
						P = text2path(pick(raretier))
						win_sound =  "sound/musical_instruments/Bell_Huge_1.ogg"
						exclamation = "Big Winner! "
					else if (roll > 50 && roll <= 200) // half decent tier, 30% chance
						P = text2path(pick(usefultier))
						exclamation = "Winner! "
					else // junk tier, 60% chance
						P = text2path(pick(junktier))
						exclamation = "Winner! "

					if (P == null)
						return
					var/obj/item/prize = new P
					prize.loc = src.loc
					prize.layer += 0.1
					src.visible_message("<span class='subtle'><b>[src]</b> says, '[exclamation][src.scan.registered] has won [prize.name]!'</span>")
					playsound(get_turf(src), "[win_sound]", 55, 1)
					src.working = 0
					src.icon_state = "slots-off"
					updateUsrDialog()

			if(operation == 2) // Eject card
				if(!src.scan)
					return TRUE // jerks doing that "hide in a chute to glitch auto-update windows out" exploit caused a wall of runtime errors
				usr.put_in_hand_or_eject(src.scan)
				src.scan = null
				src.working = FALSE
				src.icon_state = "slots-off" // just in case, some fucker broke it earlier
				src.visible_message("<span class='subtle'><b>[src]</b> says, 'Thank you for playing!'</span>")
				. = TRUE

		src.add_fingerprint(usr)
		src.updateUsrDialog()
		SEND_SIGNAL(src,COMSIG_MECHCOMP_TRANSMIT_SIGNAL, "machineUsed")
		return



/////////// fun exclusive garbage to go with the item slot machine

// todo: sprites for taxipod, taxipod's engine, demagnitized emag; gamblebuddy, barbuddy, making chefbot emaggable, probably some other stuff idk
