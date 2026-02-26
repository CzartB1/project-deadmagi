extends Unit


func ai_decisionmaking():
	var roll := randi_range(0, 100)

	# --- SHAKEN (less reliable but still functional) ---
	if current_morale_state == morale_state.shaken:
		roll -= 20 # worse judgment
	# --- NORMAL LOGIC ---
	if bind_target:
		# Escaping becomes more likely only if exhausted AND dominated
		if bind_target.current_morale<=bind_target.max_morale*0.5:
			if bind_target.current_morale<=bind_target.max_morale*0.2:
				selected_action_index = 1
			else: selected_action_index = randi_range(0,1)
		else:
			selected_action_index = 1
	else:
		# Initiate bind rarely and mostly by suitable units
		if roll <= 15:
			selected_action_index = 1
		else:
			if current_hp<=max_hp*0.3: 
				if roll < 40:
					selected_action_index=3
				else: selected_action_index = randi_range(1,3)
			else: selected_action_index = randi_range(1,3)
