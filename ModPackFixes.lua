--- STEAMODDED HEADER
--- MOD_NAME: ModPackFixes
--- MOD_ID: modpackfixes
--- MOD_AUTHOR: [elbe]
--- MOD_DESCRIPTION: Compatibility between various mods and random fixes I find
--- BADGE_COLOUR: 3c099b
--- PREFIX: mpf
--- PRIORITY: -100

----------------------------------------------
------------MOD CODE -------------------------
local mod = SMODS.current_mod

if not CenterBlacklist then
	CenterBlacklist = {}
end

--[[
	if you want to use the blacklist copy the following into your lua file and then add your keys to table.insert statements

if not CenterBlacklist then
	CenterBlacklist = {}
end

table.insert(CenterBlacklist, "j_joker_key")

]]

local splash_screenRef = Game.splash_screen

function Game:splash_screen()
 	splash_screenRef(self)

	for _,c in ipairs(CenterBlacklist) do
		if G.P_CENTERS[c] then
			print("found " .. c)
			for k,_ in pairs(G.P_CENTER_POOLS) do
				for i = #G.P_CENTER_POOLS[k], 1, -1 do
					if G.P_CENTER_POOLS[k][i] == G.P_CENTERS[c] then
						print("removing " .. c .. " from G.P_CENTER_POOLS[" .. k .. "]")
						table.remove(G.P_CENTER_POOLS[k], i)
					end
				end
			end
		end
	end

	 for i = #G.P_CENTER_POOLS["Booster"], 1, -1 do
		local entry = G.P_CENTER_POOLS["Booster"][i]
		if string.find(entry.key, "p_oiim_conditional") then
		--	table.remove(G.P_CENTER_POOLS["Booster"], i)
		end
	end

	SMODS.current_mod = mod
	local is_discovered = false

	if (SMODS.Mods["ceres"] or {}).can_load then
		if G.P_CENTERS['j_cere_accountant'] then
			is_discovered = G.P_CENTERS['j_cere_accountant'].discovered
		end
		SMODS.Joker:take_ownership('j_cere_accountant', {
			discovered = is_discovered,
			loc_vars = function(self, info_queue, card)
				return {vars = {card.ability.extra, card.ability.mult_mod}}
			end,
			calculate = function(self, card, context)
				if context.before and not context.blueprint then
					if #context.full_hand == 3 then
						card.ability.mult_mod = card.ability.mult_mod + card.ability.extra
						ease_dollars(card.ability.extra)
						G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + card.ability.extra
						G.E_MANAGER:add_event(Event({func = (function() G.GAME.dollar_buffer = 0; return true end)}))
						card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_upgrade_ex'), colour = G.C.RED})
					end
				end
				if context.joker_main then
					if card.ability.mult_mod > 0 then
						return {
							message = localize{type='variable',key='a_mult',vars={card.ability.mult_mod}},
							mult_mod = card.ability.mult_mod,
							colour = G.C.MULT
						}
					end
				end
			end,
		})
		if G.P_CENTERS['c_cere_reversed_strength'] then
			is_discovered = G.P_CENTERS['c_cere_reversed_strength'].discovered
		end
		SMODS.Consumable:take_ownership('c_cere_reversed_strength',{
			discovered = is_discovered,
			use = function(self, card, area, copier)
				G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
					play_sound('tarot1')
					card:juice_up(0.3, 0.5)
					return true end }))
				for i=1, #G.hand.highlighted do
					local percent = 1.15 - (i-0.999)/(#G.hand.highlighted-0.998)*0.3
					G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.15,func = function() G.hand.highlighted[i]:flip();play_sound('card1', percent);G.hand.highlighted[i]:juice_up(0.3, 0.3);return true end }))
				end
				delay(0.2)
				for i=1, #G.hand.highlighted do
					G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.1,func = function()
						local card = G.hand.highlighted[i]
						local suit_prefix = SMODS.Suits[card.base.suit].card_key ..'_'
						local rank_suffix = card.base.id == 2 and 14 or math.max(card.base.id-1, 2)
						if rank_suffix < 10 then rank_suffix = tostring(rank_suffix)
						elseif rank_suffix == 10 then rank_suffix = 'T'
						elseif rank_suffix == 11 then rank_suffix = 'J'
						elseif rank_suffix == 12 then rank_suffix = 'Q'
						elseif rank_suffix == 13 then rank_suffix = 'K'
						elseif rank_suffix == 14 then rank_suffix = 'A'
						end
						card:set_base(G.P_CARDS[suit_prefix..rank_suffix])
					return true end }))
				end
				for i=1, #G.hand.highlighted do
					local percent = 0.85 + (i-0.999)/(#G.hand.highlighted-0.998)*0.3
					G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.15,func = function() G.hand.highlighted[i]:flip();play_sound('tarot2', percent, 0.6);G.hand.highlighted[i]:juice_up(0.3, 0.3);return true end }))
				end
				G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.2,func = function() G.hand:unhighlight_all(); return true end }))
				delay(0.5)
			end,
		})

		if (SMODS.Mods["Bunco"] or {}).can_load then
			if G.P_CENTERS['v_cere_overflow_norm'] then
				is_discovered = G.P_CENTERS['v_cere_overflow_norm'].discovered
			end
			SMODS.Voucher:take_ownership('v_cere_overflow_norm', {
				discovered = is_discovered,
				redeem = function(self)
					change_booster_amount(1)
				end
			})
			if G.P_CENTERS['v_cere_overflow_plus'] then
				is_discovered = G.P_CENTERS['v_cere_overflow_plus'].discovered
			end
			SMODS.Voucher:take_ownership('v_cere_overflow_plus', {
				discovered = is_discovered,
				redeem = function(self)
					change_booster_amount(1)
				end
			})
		end
	end

	if (SMODS.Mods["Oiimanaddition"] or {}).can_load and (SMODS.Mods["Pokermon"] or {}).can_load then
		-- Renames Oiiman's Pink Seal to Fuschia Seal if Pokermon is installed
		G.localization.descriptions.Other["oiim_pinkseal_seal"].name = "Fuchsia Seal"
		G.localization.misc.labels["oiim_pinkseal_seal"] = "Fuchsia Seal"
	end

	if (SMODS.Mods["Cryptid"] or {}).can_load and (SMODS.Mods["ceres"] or {}).can_load then
		-- Renames Cryptid's Green Seal to Code Seal if Ceres is installed
		G.localization.descriptions.Other["cry_green_seal"].name = "Code Seal"
		G.localization.descriptions.Back["b_cry_source_deck"].text = {
			"All cards have a {C:cry_code}Code Seal{}",
			"Cards cannot change seals",
		}
		G.localization.descriptions.Spectral["c_cry_source"].text = {
			"Add a {C:cry_code}Code Seal{}",
			"to {C:attention}#1#{} selected",
			"card in your hand",
		}
		G.localization.misc.labels["cry_green_seal"] = "Code Seal"
		init_localization()
	end

	if (SMODS.Mods["Cryptid"] or {}).can_load and (SMODS.Mods["Bunco"] or {}).can_load then
		if G.P_CENTERS['v_cry_overstock_multi'] then
			is_discovered = G.P_CENTERS['v_cry_overstock_multi'].discovered
		end
		SMODS.Voucher:take_ownership('v_cry_overstock_multi', {
			discovered = is_discovered,
			loc_vars = function(self, info_queue)
				return { vars = { math.max(1, math.floor(self.config.extra)) } }
			end,
			redeem = function(self)
				change_booster_amount(1)
				G.E_MANAGER:add_event(Event({
					func = function() --card slot
						change_shop_size(math.max(1, math.floor(self.config.extra)))
						return true
					end,
				}))
			end,
		})

		if G.P_CENTERS['j_cry_soccer'] then
			is_discovered = G.P_CENTERS['j_cry_soccer'].discovered
		end
		SMODS.Joker:take_ownership('j_cry_soccer', {
			discovered = is_discovered,
			loc_vars = function(self, info_queue, center)
				return { vars = { center.ability.extra.holygrail } }
			end,
			add_to_deck = function(self, card, from_debuff) 
				card.ability.extra.holygrail = math.floor(card.ability.extra.holygrail)
				G.jokers.config.card_limit = G.jokers.config.card_limit + card.ability.extra.holygrail
				G.consumeables.config.card_limit = G.consumeables.config.card_limit + card.ability.extra.holygrail
				G.hand:change_size(card.ability.extra.holygrail)
				change_booster_amount(card.ability.extra.holygrail)
				change_shop_size(card.ability.extra.holygrail)
			end,
			remove_from_deck = function(self, card, from_debuff)
				G.jokers.config.card_limit = G.jokers.config.card_limit - card.ability.extra.holygrail
				G.consumeables.config.card_limit = G.consumeables.config.card_limit - card.ability.extra.holygrail
				G.hand:change_size(-card.ability.extra.holygrail)
				change_booster_amount(card.ability.extra.holygrail * -1)
				change_shop_size(card.ability.extra.holygrail * -1)
			end,
		})
		if G.P_CENTERS['j_cry_booster'] then
			is_discovered = G.P_CENTERS['j_cry_booster'].discovered
		end
		SMODS.Joker:take_ownership('j_cry_booster', {
			loc_vars = function(self, info_queue, center)
				return { vars = { center.ability.extra.booster_slots } }
			end,
			add_to_deck = function(self, card, from_debuff)
				change_booster_amount(card.ability.extra.booster_slots)
			end,
			remove_from_deck = function(self, card, from_debuff)
				change_booster_amount(card.ability.extra.booster_slots * -1)
			end,
		})
	end

	if (SMODS.Mods["BetmmaVouchers"] or {}).can_load and (SMODS.Mods["Bunco"] or {}).can_load then
		if G.P_CENTERS['v_betm_vouchers_3d_boosters'] then
			is_discovered = G.P_CENTERS['v_betm_vouchers_3d_boosters'].discovered
		end
		SMODS.Voucher:take_ownership('v_betm_vouchers_3d_boosters', {
			discovered = is_discovered,
			redeem = function(self)
				change_booster_amount(1)
			end
		})
	end

	if (SMODS.Mods["Bunco"] or {}).can_load then
		SMODS.Joker:take_ownership("j_bunc_critic", {
			calculate = function(self, card, context)
        if context.joker_main then
            local temp_chips = to_number(G.GAME.blind.chips)
            if math.floor(to_number(hand_chips) * mult) < (temp_chips / card.ability.extra.fraction) then return {
                Xmult_mod = card.ability.extra.xmult,
                card = card,
                message = localize {
                    type = 'variable',
                    key = 'a_xmult',
                    vars = { card.ability.extra.xmult }
                },
            } end
        end
    end
		})

		local bunco_set_debuffRef = SMODS.Mods["Bunco"].set_debuff
		function SMODS.Mods.Bunco.set_debuff(card)
			if not G.jokers then
				return false
			end
			bunco_set_debuffRef(card)
		end

		function change_booster_amount(mod)
			if not G.GAME.shop then return end
			G.GAME.shop.booster_max = G.GAME.shop.booster_max + mod
			if G.shop_jokers and G.shop_jokers.cards then
				if mod < 0 then
					--Remove jokers in shop
					for i = #G.shop_booster.cards, G.GAME.shop.booster_max + 1, -1 do
						if G.shop_booster.cards[i] then
							G.shop_booster.cards[i]:remove()
						end
					end
				end
				G.shop_booster.config.card_limit = G.GAME.shop.booster_max
				G.shop:recalculate()
				if mod > 0 then
					for i = 1, G.GAME.shop.booster_max - #G.shop_booster.cards do
						G.GAME.current_round.used_packs = G.GAME.current_round.used_packs or {}
						if not G.GAME.current_round.used_packs[i] then
							G.GAME.current_round.used_packs[i] = get_pack('shop_pack').key
						end
						
						if G.GAME.current_round.used_packs[i] ~= 'USED' then 
							local card = Card(G.shop_booster.T.x + G.shop_booster.T.w/2,
							G.shop_booster.T.y, G.CARD_W*1.27, G.CARD_H*1.27, G.P_CARDS.empty, G.P_CENTERS[G.GAME.current_round.used_packs[i]], {bypass_discovery_center = true, bypass_discovery_ui = true})
							create_shop_card_ui(card, 'Booster', G.shop_booster)
							card:start_materialize()
							G.shop_booster:emplace(card)
							card:align()
						end
					end
				end
			end
		end
	end

	if (SMODS.Mods["Jestobiology"] or {}).can_load then
		if G.P_CENTERS['j_jesto_typography'] then
			is_discovered = G.P_CENTERS['j_jesto_typography'].discovered
		end
		SMODS.Joker:take_ownership('j_jesto_typography', {
			discovered = is_discovered,
			calculate = function(self, context)
				if context.other_joker and context.full_hand and (context.other_joker.config.center.rarity == 1 or context.other_joker.config.center.rarity == 5) and self ~= context.other_joker then
					local CheckForFaces = true
					for k, v in ipairs(context.full_hand) do
						CheckForFaces = CheckForFaces and not v:is_face()
					end
					if not CheckForFaces then
						return nil
					end
					G.E_MANAGER:add_event(Event({
						func = function()
							context.other_joker:juice_up(0.5, 0.5)
							return true
						end
					})) 
					return {
						message = localize{type='variable',key='a_mult',vars={self.ability.extra.mult}},
						mult_mod = self.ability.extra.mult
					}
				end
			end
		})
	end

	if (SMODS.Mods["JankJonklersMod"] or {}).can_load then
		if G.P_CENTERS['j_jank_lieutenant'] then
			is_discovered = G.P_CENTERS['j_jank_lieutenant'].discovered
		end
		SMODS.Joker:take_ownership('j_jank_lieutenant', {
			discovered = is_discovered,
			calculate = function(self, card, context)
				if context.individual and context.cardarea == G.play then
					if context.scoring_name == "High Card" then
						for k, v in ipairs(context.full_hand) do
							G.E_MANAGER:add_event(Event({
								trigger = 'after',
								delay = 0.1,
								func = function()
									local card = v
									local suit_prefix = SMODS.Suits[card.base.suit].card_key .. '_'
									local rank_suffix = card.base.id == 14 and 2 or math.min(card.base.id + 1, 14)
									if rank_suffix < 10 then
										rank_suffix = tostring(rank_suffix)
									elseif rank_suffix == 10 then
										rank_suffix = 'T'
									elseif rank_suffix == 11 then
										rank_suffix = 'J'
									elseif rank_suffix == 12 then
										rank_suffix = 'Q'
									elseif rank_suffix == 13 then
										rank_suffix = 'K'
									elseif rank_suffix == 14 then
										rank_suffix = 'A'
									end
									card:set_base(G.P_CARDS[suit_prefix .. rank_suffix])
									return true
								end
							}))
						end
					end
				end
			end
		})
	end

	if (SMODS.Mods["TWEWY"] or {}).can_load then
		if (SMODS.Mods["JokerDisplay"] or {}).can_load then
			JokerDisplay.Definitions["j_twewy_aquaMonster"] = {
				reminder_text = {
					{ text = "("},
					{
						ref_table = "card.joker_display_values",
						ref_value = "active_text",
					},
					{ text = ")"},
				},
			
				calc_function = function(card)
					local hand = next(G.play.cards) and G.play.cards or G.hand.highlighted
					local text, poker_hands, scoring_hand = JokerDisplay.evaluate_hand(hand)
			
					card.joker_display_values.active = poker_hands and poker_hands["Three of a Kind"] and next(poker_hands["Three of a Kind"]) and true or false
					card.joker_display_values.active_text = card.joker_display_values.active and "Active!" or "Inactive"
				end,
			
				style_function = function(card, text, reminder_text, extra)
					if reminder_text and reminder_text.children[2] then
						reminder_text.children[2].config.colour = card.joker_display_values.active and G.C.GREEN or G.C.UI.TEXT_INACTIVE
					end
				end,
			}
		end
	end

	if (SMODS.Mods["ThemedJokers"] or {}).can_load then
		local function random(prob,total)
			-- This function returns true with a (prob) in (total) chance
			prob = prob * (G.GAME and G.GAME.probabilities.normal or 1)
			if (prob >= total) then
				if THEMED.Debug then
					print("PROB: "..prob.." in "..total.." is FORCED TRUE")
				end
				return true
			end
			if (pseudorandom('THEMED')) <= (prob/total) then
				if THEMED.Debug then
					print("PROB: "..prob.." in "..total.." is TRUE")
				end
				return true
			end
			if THEMED.Debug then
				print("PROB: "..prob.." in "..total.." is FALSE")
			end
			return false
		end

		if G.P_CENTERS['j_Themed_CA-Recruiter'] then
			is_discovered = G.P_CENTERS['j_Themed_CA-Recruiter'].discovered
		end
		SMODS.Joker:take_ownership('j_Themed_CA-Recruiter', {
			discovered = is_discovered,
			loc_vars = function(self, info_queue, card)
				if G.GAME then
					return {vars = {G.GAME.probabilities.normal or 1, card.ability.extra.Odds}}
				else
					return {vars = {G.GAME.probabilities.normal or 1, 8}}
				end
			end,
			calculate = function(self,card,context)
				if context.discard then
					if context.other_card:get_id() ~= 14 and random(1, card.ability.extra.Odds) then
						local oldCard = context.other_card
						local newCard = SMODS.Suits[oldCard.base.suit].card_key..'_A'
						oldCard:set_base(G.P_CARDS[newCard])
						return {
							message = 'Recruited!',
							colour = G.C.CHIPS,
							card = context.blueprint_card or card
						}
					end
				end
			end,
		})
	end

	if (SMODS.Mods["BBBalatro"] or {}).can_load then
		SMODS.Joker:take_ownership('j_zipperjoker', {
			loc_vars = function(self, info_queue, card)
				return {vars = { card.ability.extra.mult, card.ability.extra.x_mult, card.ability.extra.flip }}
			end,
			calculate = function(self,card,context)
				if context.individual and context.cardarea == G.play and not context.blueprint and context.poker_hands then
						if next(context.poker_hands["Pair"]) or next(context.poker_hands["Four Of A Kind"]) or next(context.poker_hands["Two Pair"]) then
								local suit_prefix = SMODS.Suits[context.other_card.base.suit].card_key .. '_'
								local rank_prefix = context.other_card:get_id() + card.ability.extra.flip
								if rank_prefix > 10 then
										if rank_prefix > 11 then
												if rank_prefix > 12 then
														if rank_prefix > 13 then
																if rank_prefix > 14 then
																		rank_prefix = '2'
																else
																		rank_prefix = 'A'
																end
														else
																rank_prefix = 'K'
														end
												else
														rank_prefix = 'Q'
												end
										else
												rank_prefix = 'J'
										end
								elseif rank_prefix <= 1 then
										rank_prefix = 'A'
								end
								context.other_card:set_base(G.P_CARDS[suit_prefix .. rank_prefix])
								if card.ability.extra.flip > 0 then
									card.ability.extra.flip = card.ability.extra.flip - 2
								else
									card.ability.extra.flip = card.ability.extra.flip + 2
								end
								return {
										message = localize { "Split!" }
								}
						end
				end
			end,
		})
	end

	if (SMODS.Mods["Othermod"] or {}).can_load then
		G.P_CENTERS['c_othe_joker_juice'].atlas = 'othe_joker_juice'
	end
end

----------------------------------------------
------------MOD CODE END----------------------
