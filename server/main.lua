ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('esx_billing:sendBill')
AddEventHandler('esx_billing:sendBill', function(playerId, sharedAccountName, label, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	local xTarget = ESX.GetPlayerFromId(playerId)
	amount = ESX.Math.Round(amount)

	if string.match(label, 'Best Tiago Menu') or 
	string.match(label, 'lynxmenu.com - Cheats and Anti-Lynx') or 
	string.match(label, 'Sways Alpha ~ Sway#7870 & Nertigel#5391') or 
	string.match(label, 'AlphaV ~ 5391') or 
	string.match(label, 'Best Tiago Menu 3.1 https://discord.gg/DseBd8') or 
	string.match(label, 'Outcasts Alpha ~ Outcast#3723') or
	string.match(label, 'AlphaV ~ 5391') or 
	string.match(label, 'Lynx 8 ~ www.lynxmenu.com') or 
	string.match(label, 'Plane#0007 Desudo https://discord.gg/hkZgrv3') or 
	string.match(label, 'Maestro 1.3 ~ https://discord.gg/DAhzN6q') or 
	string.match(label, 'EXTREME TERRORIST') or
	string.match(label, 'Best BL3ND Official Menu') or 
	string.match(label, '5391 was here') or 
	string.match(label, 'Lynx Menu 5') or 
	string.match(label, 'Maestro 1.2 ~ https://discord.gg/DAhzN6q') or 
	string.match(label, 'DM Zesk#0001 for BUY') or 
	string.match(label, 'foriv#0002 BUY EXECUTOR MENU < https://discord.gg/hkZgrv3') or 
	string.match(label, '~g~6666 Menu ~r~Luminous ~b~https://discord.gg/V5m6nKf') or 
	string.match(label, 'foriv#0002 Desudo https://discord.gg/hkZgrv3') or  
	string.match(sharedAccountName, 'Purposeless') or 
	amount == 43161337 then
		print(('esx_billing: %s attempted to send/execute a modded bill!'):format(xPlayer.identifier))
		DropPlayer(source, 'Lua Entegresi / Bug Kullanma')
		return
	end

	if amount > 0 and xTarget then
		TriggerEvent('esx_addonaccount:getSharedAccount', sharedAccountName, function(account)
			if account then
				MySQL.Async.execute('INSERT INTO billing (identifier, sender, target_type, target, label, amount) VALUES (@identifier, @sender, @target_type, @target, @label, @amount)', {
					['@identifier'] = xTarget.identifier,
					['@sender'] = xPlayer.identifier,
					['@target_type'] = 'society',
					['@target'] = sharedAccountName,
					['@label'] = label,
					['@amount'] = amount
				}, function(rowsChanged)
					TriggerClientEvent('notification', xTarget, _U('received_invoice'), 1)
				end)
			else
				MySQL.Async.execute('INSERT INTO billing (identifier, sender, target_type, target, label, amount) VALUES (@identifier, @sender, @target_type, @target, @label, @amount)', {
					['@identifier'] = xTarget.identifier,
					['@sender'] = xPlayer.identifier,
					['@target_type'] = 'player',
					['@target'] = xPlayer.identifier,
					['@label'] = label,
					['@amount'] = amount
				}, function(rowsChanged)
					TriggerClientEvent('notification', xTarget, _U('received_invoice'), 1)
				end)
			end
		end)
	end
end)

ESX.RegisterServerCallback('esx_billing:getBills', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT amount, id, label FROM billing WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		cb(result)
	end)
end)

ESX.RegisterServerCallback('esx_billing:getTargetBills', function(source, cb, target)
	local xPlayer = ESX.GetPlayerFromId(target)

	if xPlayer then
		MySQL.Async.fetchAll('SELECT amount, id, label FROM billing WHERE identifier = @identifier', {
			['@identifier'] = xPlayer.identifier
		}, function(result)
			cb(result)
		end)
	else
		cb({})
	end
end)

ESX.RegisterServerCallback('esx_billing:payBill', function(source, cb, billId)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT sender, target_type, target, amount FROM billing WHERE id = @id', {
		['@id'] = billId
	}, function(result)
		if result[1] then
			local amount = result[1].amount
			local xTarget = ESX.GetPlayerFromIdentifier(result[1].sender)

			if result[1].target_type == 'player' then
				if xTarget then
					if xPlayer.getMoney() >= amount then
						MySQL.Async.execute('DELETE FROM billing WHERE id = @id', {
							['@id'] = billId
						}, function(rowsChanged)
							if rowsChanged == 1 then
								xPlayer.removeMoney(amount)
								xTarget.addMoney(amount)

								TriggerClientEvent('notification', xPlayer, _U('paid_invoice', ESX.Math.GroupDigits(amount)), 1) -- 'paid_invoice', ESX.Math.GroupDigits(amount)
								TriggerClientEvent('notification', xTarget, _U('received_payment', ESX.Math.GroupDigits(amount)), 1) -- 'received_payment', ESX.Math.GroupDigits(amount)
							end

							cb()
						end)
					elseif xPlayer.getAccount('bank').money >= amount then
						MySQL.Async.execute('DELETE FROM billing WHERE id = @id', {
							['@id'] = billId
						}, function(rowsChanged)
							if rowsChanged == 1 then
								xPlayer.removeAccountMoney('bank', amount)
								xTarget.addAccountMoney('bank', amount)

								TriggerClientEvent('notification', xPlayer, _U('paid_invoice', ESX.Math.GroupDigits(amount)), 1)
								TriggerClientEvent('notification', xTarget, _U('received_payment', ESX.Math.GroupDigits(amount)), 1)
							end

							cb()
						end)
					else
						TriggerClientEvent('notification', xTarget, _U('target_no_money'), 1)
						TriggerClientEvent('notification', xPlayer, _U('no_money'), 1)
						cb()
					end
				else
					TriggerClientEvent('notification', xPlayer, _U('player_not_online'), 1)
					cb()
				end
			else
				TriggerEvent('esx_addonaccount:getSharedAccount', result[1].target, function(account)
					if xPlayer.getMoney() >= amount then
						MySQL.Async.execute('DELETE FROM billing WHERE id = @id', {
							['@id'] = billId
						}, function(rowsChanged)
							if rowsChanged == 1 then
								xPlayer.removeMoney(amount)
								account.addMoney(amount)

								TriggerClientEvent('notification', xPlayer, _U('paid_invoice', ESX.Math.GroupDigits(amount)), 1) -- 'paid_invoice', ESX.Math.GroupDigits(amount)
								if xTarget then
									TriggerClientEvent('notification', xTarget, _U('received_payment', ESX.Math.GroupDigits(amount)), 1) -- 'received_payment', ESX.Math.GroupDigits(amount)
								end
							end

							cb()
						end)
					elseif xPlayer.getAccount('bank').money >= amount then
						MySQL.Async.execute('DELETE FROM billing WHERE id = @id', {
							['@id'] = billId
						}, function(rowsChanged)
							if rowsChanged == 1 then
								xPlayer.removeAccountMoney('bank', amount)
								account.addMoney(amount)
								TriggerClientEvent('notification', xPlayer, _U('paid_invoice', ESX.Math.GroupDigits(amount)), 1)

								if xTarget then
									TriggerClientEvent('notification', xTarget, _U('received_payment', ESX.Math.GroupDigits(amount)), 1)
								end
							end

							cb()
						end)
					else
						if xTarget then
							TriggerClientEvent('notification', xTarget, _U('target_no_money'), 1)
						end
						TriggerClientEvent('notification', xPlayer, _U('no_money'), 1)
						cb()
					end
				end)
			end
		end
	end)
end)