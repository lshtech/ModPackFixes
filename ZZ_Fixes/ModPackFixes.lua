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
local splash_screenRef = Game.splash_screen

function Game:splash_screen()
 	splash_screenRef(self)

	SMODS.current_mod = mod

	if (SMODS.Mods["ceres"] or {}).can_load then
		SMODS.Joker:take_ownership('j_cere_accountant', {
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
		SMODS.Consumable:take_ownership('c_cere_reversed_strength',{
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
			SMODS.Voucher:take_ownership('v_cere_overflow_norm', {
				redeem = function(self)
					change_booster_amount(1)
				end
			})
			SMODS.Voucher:take_ownership('v_cere_overflow_plus', {
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
		SMODS.Voucher:take_ownership('v_cry_overstock_multi', {
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

		SMODS.Joker:take_ownership('j_cry_soccer', {
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
		SMODS.Voucher:take_ownership('v_betm_vouchers_3d_boosters', {
			redeem = function(self)
				change_booster_amount(1)
			end
		})
	end

	if (SMODS.Mods["Bunco"] or {}).can_load then
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
		SMODS.Joker:take_ownership('j_jesto_typography', {
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

	if (SMODS.Mods["familiar"] or {}).can_load then
		SMODS.Consumable:take_ownership('c_fam_vigor', {
			loc_txt = {
				['en-us'] = {
					name = "Vigor",
					text = {
						"Increases rank of",
						"{C:attention}one{} selected card",
						"by {C:attention}3",
					}
				}
			},
			use = function(self, card)
				for i = 1, #G.hand.highlighted do
					for j = 1, 3 do
						G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.1,func = function()
							local card = G.hand.highlighted[i]
							local suit_prefix = SMODS.Suits[card.base.suit].card_key ..'_'
							local rank_suffix = card.base.id == 14 and 2 or math.min(card.base.id+1, 14)
							if rank_suffix < 10 then rank_suffix = tostring(rank_suffix)
							elseif rank_suffix == 10 then rank_suffix = 'T'
							elseif rank_suffix == 11 then rank_suffix = 'J'
							elseif rank_suffix == 12 then rank_suffix = 'Q'
							elseif rank_suffix == 13 then rank_suffix = 'K'
							elseif rank_suffix == 14 then rank_suffix = 'A'
							end
							card:juice_up(0.3, 0.5)
							card:set_base(G.P_CARDS[suit_prefix..rank_suffix])
						return true end }))
					end
				end  
			end,
		})
	end

	if (SMODS.Mods["JankJonklersMod"] or {}).can_load then
		SMODS.Joker:take_ownership('j_jank_lieutenant', {
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

	if (SMODS.Mods["KCVanilla"] or {}).can_load then
		local function kcv_get_suit_prefix(card)
			local suit_prefix = SMODS.Suits[card.base.suit].card_key
			return suit_prefix
		end
		
		local function kcv_get_rank_suffix(id)
			if id < 10 then
				return tostring(id)
			elseif id == 10 then
				return 'T'
			elseif id == 11 then
				return 'J'
			elseif id == 12 then
				return 'Q'
			elseif id == 13 then
				return 'K'
			else
				return 'A'
			end
		end
		
		local function kcv_get_rank_up_pcard(card)
			local suit_prefix = kcv_get_suit_prefix(card)
			local rank_suffix = kcv_get_rank_suffix(math.min(card.base.id + 1, 14))
			return G.P_CARDS[suit_prefix .. '_' .. rank_suffix]
		end
		
		local function kcv_rank_up_discreetly(card)
			local newcard = kcv_get_rank_up_pcard(card)
			card.kcv_ignore_debuff_check = true
			card.kcv_ranked_up_discreetly = true
			card.kcv_display_id = card.kcv_display_id and card.kcv_display_id or card.base.id
			card:set_base(newcard)
		end

		SMODS.Joker:take_ownership('j_kcva_5day', {
			calculate = function(self, card, context)
				-- TODO: How should this behave with Midas?
				-- kcv_forecast_event is like `before` but occurs just prior.
				-- Using `before` directly causes weird *player-perceived* desyncs between kcv_rank_up_discreetly, E_MANAGER events, and other calcs 
				if context.kcv_forecast_event and context.scoring_hand then
					if next(context.poker_hands["Straight"]) then
						for i, other_c in ipairs(context.scoring_hand) do
							if other_c:get_id() ~= 14 then
								kcv_rank_up_discreetly(other_c)
							end
						end
					end
				end
				if context.before and context.scoring_hand then
					if next(context.poker_hands["Straight"]) then
						local targets = {}
						for i, other_c in ipairs(context.scoring_hand) do
							if other_c.kcv_ranked_up_discreetly then
								table.insert(targets, other_c)
							end
						end
		
						card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {
							message = localize('k_active_ex'),
							colour = G.C.FILTER,
							card = context.blueprint_card or card
						});
		
						for i_2, other_c_2 in ipairs(targets) do
							local percent = 1.15 - (i_2 - 0.999) / (#G.hand.cards - 0.998) * 0.3
							G.E_MANAGER:add_event(Event({
								func = function()
									if not other_c_2.kcv_ranked_up_discreetly then
										-- was complete, but another 5-day joker is targeting this card
										return true
									end
									play_sound('card1', percent)
									other_c_2:flip()
									return true
								end
							}))
							delay(0.15)
						end
						delay(0.3)
						for i_3, other_c_3 in ipairs(targets) do
							local percent = 0.85 + (i_3 - 0.999) / (#G.hand.cards - 0.998) * 0.3
							G.E_MANAGER:add_event(Event({
								func = function()
									if not other_c_3.kcv_ranked_up_discreetly then
										-- was complete, but another 5-day joker is targeting this card
										return true
									end
									-- kcv_log(other_c_3.base.id .. ' - ' .. other_c_3.kcv_display_id)
									other_c_3.kcv_display_id = other_c_3.kcv_display_id + 1
									local suit_prefix = kcv_get_suit_prefix(other_c_3)
									local rank_suffix = kcv_get_rank_suffix(other_c_3.kcv_display_id)
									local newcard = G.P_CARDS[suit_prefix .. '_' .. rank_suffix]
									-- set_base again to update sprites that were postponed by kcv_ranked_up_discreetly
									other_c_3:set_sprites(nil, newcard)
									play_sound('tarot2', percent, 0.6)
									other_c_3:flip()
									if other_c_3.kcv_display_id >= other_c_3.base.id then
										-- cleanup
										other_c_3.kcv_ranked_up_discreetly = nil
										other_c_3.kcv_ignore_debuff_check = nil
										other_c_3.kcv_display_id = nil
									end
									return true
								end
							}))
							delay(0.15)
						end
					end
				end
			end
		})
	end

	if (SMODS.Mods["TWEWY"] or {}).can_load then
		SMODS.Joker:take_ownership('j_twewy_loveMeTether', {
			loc_vars = function(self, info_queue, center)
				return {vars = {center.ability.extra.name}}
			end,
			calculate = function(self, card, context)
				if context.discard
				and context.other_card:is_suit("Hearts") then
					for i, v in ipairs(G.hand.cards) do
						if not v.highlighted and v.base.id ~= 14 then
							G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.1,func = function()
								local percent = 1.15 - (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
								play_sound('card1', percent)
								v:flip()
							return true end }))
							delay(0.05)
							card.ability.extra.usedThisHand = true
						end
					end
					
					if card.ability.extra.usedThisHand then
						delay(0.1)
						for i, v in ipairs(G.hand.cards) do
							if not v.highlighted and v.base.id ~= 14 then
								G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.1,func = function()
									local _card = v
									local suit_prefix = SMODS.Suits[_card.base.suit].card_key..'_'
									local rank_suffix = v.base.id + 1
									if rank_suffix < 10 then rank_suffix = tostring(rank_suffix)
									elseif rank_suffix == 10 then rank_suffix = 'T'
									elseif rank_suffix == 11 then rank_suffix = 'J'
									elseif rank_suffix == 12 then rank_suffix = 'Q'
									elseif rank_suffix == 13 then rank_suffix = 'K'
									elseif rank_suffix == 14 then rank_suffix = 'A'
									elseif rank_suffix == 15 then rank_suffix = 'A'
									end
									_card:set_base(G.P_CARDS[suit_prefix..rank_suffix])
									local percent = 0.85 + (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
									play_sound('tarot2', percent, 0.6)
									_card:flip()
								return true end }))
								delay(0.05)
							end
						end
						delay(0.1)
					end
					card.ability.extra.usedThisHand = false
				end
			end
		})

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

		SMODS.Joker:take_ownership('j_Themed_CA-Recruiter', {
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
end

----------------------------------------------
------------MOD CODE END----------------------
