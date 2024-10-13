--- STEAMODDED HEADER
--- MOD_NAME: ModPackFixes
--- MOD_ID: modpackfixes
--- MOD_AUTHOR: [elbe]
--- MOD_DESCRIPTION: Compatibility between this and other mods
--- BADGE_COLOUR: 3c099b
--- PREFIX: mpf

----------------------------------------------
------------MOD CODE -------------------------
local mod = SMODS.current_mod
local splash_screenRef = Game.splash_screen

function Game:splash_screen()
 	splash_screenRef(self)

	SMODS.current_mod = mod
	
	if (SMODS.Mods["ceres"] or {}).can_load  then
		SMODS.Joker:take_ownership('j_cere_accountant', {
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
	end

	if (SMODS.Mods["ceres"] or {}).can_load and (SMODS.Mods["Bunco"] or {}).can_load then
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
	if (SMODS.Mods["Cryptid"] or {}).can_load and (SMODS.Mods["Bunco"] or {}).can_load then
		SMODS.Voucher:take_ownership('v_cry_overstock_multi', {
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
				return
			end
			bunco_set_debuffRef(self, card)
		end
	end
	
	if (SMODS.Mods["Jestobiology"] or {}).can_load  then
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

	if (SMODS.Mods["JokerDisplay"] or {}).can_load and (SMODS.Mods["TWEWY"] or {}).can_load  then
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






----------------------------------------------
------------MOD CODE END----------------------
