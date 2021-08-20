-- LightSectored portrayal rules file.

local function nmi2metres(nmi)
	return nmi * 1852.0
end

-- Sector values are given from seaward, this function flips them.
local function flipSector(sector)
	if sector < 180.0 then
		return sector + 180.0
	else
		return sector - 180.0
	end
end

-- Main entry point for feature type.
function LightSectored(feature, featurePortrayal, contextParameters)
	if feature.PrimitiveType ~= PrimitiveType.Point then
		error('LightSectored must be of spatial type point')
	end

	if contextParameters.RadarOverlay then
		featurePortrayal:AddInstructions('ViewingGroup:27070;DrawingPriority:24;DisplayPlane:OverRADAR;Hover:true')
	else
		featurePortrayal:AddInstructions('ViewingGroup:27070;DrawingPriority:24;DisplayPlane:UnderRADAR;Hover:true')
	end

	for isc, sectorCharacteristic in ipairs(feature.sectorCharacteristics) do
		for ils, lightSector in ipairs(sectorCharacteristic.lightSector) do
			local valueOfNominalRange = 9.0

			if lightSector.valueOfNominalRange then
				valueOfNominalRange = lightSector.valueOfNominalRange:ToNumber()
			end

			local colour = lightSector.colour
			local sectorColourToken
			local sectorLightSymbol

			if colour[1] == 1 and colour[2] == 3 then -- white and red
				sectorColourToken = 'LITRD'
				sectorLightSymbol = 'LIGHTS11'
			elseif colour[1] == 3 then -- red
				sectorColourToken = 'LITRD'
				sectorLightSymbol = 'LIGHTS11'
			elseif colour[1] == 1 and colour[2] == 4 then -- white and green
				sectorColourToken = 'LITGN'
				sectorLightSymbol = 'LIGHTS12'
			elseif colour[1] == 4 then -- green
				sectorColourToken = 'LITGN'
				sectorLightSymbol = 'LIGHTS12'
			elseif colour[1] == 11 or colour[1] == 6 or colour[1] == 1 then -- orange or yellow or white
				sectorColourToken = 'LITYW'
				sectorLightSymbol = 'LIGHTS13'
			elseif colour[1] == 1 and colour[2] == 6 then -- blue and yellow
				sectorColourToken = 'LITYW'
				sectorLightSymbol = 'LIGHTS13'
			else
				sectorColourToken = 'CHMGD'
				sectorLightSymbol = 'LITDEF11'
			end

			if lightSector.sectorLimit then
				-- Sectored light.
				local sectorLimit1 = flipSector(lightSector.sectorLimit.sectorLimitOne.sectorBearing:ToNumber())
				local sectorLimit2 = flipSector(lightSector.sectorLimit.sectorLimitTwo.sectorBearing:ToNumber())
				
				if sectorLimit2 < sectorLimit1 then
					sectorLimit2 = sectorLimit2 + 360.0
				end

				-- Draw leg lines

				local leglen1
				local leglen2
				local crsLength1
				local crsLength2
				
				if contextParameters.SLLSwitch then
					-- Norway / AHO proposal for portrayal of sectored lights
					if contextParameters.FullSectors then
						leglen1 = nmi2metres(valueOfNominalRange)
						leglen2 = leglen1
						crsLength1 = 'GeographicCRS'
						crsLength2 = 'GeographicCRS'
					else
						if lightSector.sectorLimit.sectorLimitOne.sectorLineLength then
							leglen1 = lightSector.sectorLimit.sectorLimitOne.sectorLineLength
							crsLength1 = 'GeographicCRS'
						else
							leglen1 = 25.0
							crsLength1 = 'LocalCRS'
						end
						if lightSector.sectorLimit.sectorLimitTwo.sectorLineLength then
							leglen2 = lightSector.sectorLimit.sectorLimitTwo.sectorLineLength
							crsLength2 = 'GeographicCRS'
						else
							leglen2 = 25.0
							crsLength2 = 'LocalCRS'
						end
					end
				else
					-- NIWC proposal for portrayal of sectored lights
					if contextParameters.FullSectors then
						if lightSector.sectorLimit.sectorLimitOne.sectorLineLength then
							leglen1 = lightSector.sectorLimit.sectorLimitOne.sectorLineLength
						else
							leglen1 = nmi2metres(valueOfNominalRange)
						end
						if lightSector.sectorLimit.sectorLimitTwo.sectorLineLength then
							leglen2 = lightSector.sectorLimit.sectorLimitTwo.sectorLineLength
						else
							leglen2 = nmi2metres(valueOfNominalRange)
						end
						crsLength1 = 'GeographicCRS'
						crsLength2 = 'GeographicCRS'
					else
						leglen1 = 25.0
						leglen2 = 25.0
						crsLength1 = 'LocalCRS'
						crsLength2 = 'LocalCRS'
					end
				end

				featurePortrayal:AddInstructions('AugmentedRay:GeographicCRS,' .. sectorLimit1 .. ',' .. crsLength1 .. ',' .. leglen1)
				featurePortrayal:SimpleLineStyle('dash',0.32,'CHBLK')
				featurePortrayal:AddInstructions('LineInstruction:_simple_')
				featurePortrayal:AddInstructions('AugmentedRay:GeographicCRS,' .. sectorLimit2 .. ',' .. crsLength2 .. ',' .. leglen2)
				featurePortrayal:AddInstructions('LineInstruction:_simple_')

				-- Draw sector arcs

				featurePortrayal:AddInstructions('ArcByRadius:0,0,' .. (lightSector.sectorExtension or 0.0) + 20.0 .. ',' .. sectorLimit1 .. ',' .. sectorLimit2 - sectorLimit1)
				featurePortrayal:AddInstructions('AugmentedPath:LocalCRS,GeographicCRS,LocalCRS')

				if contains(lightSector.lightVisibility, { 7, 6, 3 }) then
					featurePortrayal:SimpleLineStyle('dash',0.32,'CHBLK') -- Redundant?
					featurePortrayal:AddInstructions('LineInstruction:_simple_')
				else
					featurePortrayal:SimpleLineStyle('solid',1.28,'OUTLW')
					featurePortrayal:AddInstructions('LineInstruction:_simple_')
					featurePortrayal:SimpleLineStyle('solid',0.64,sectorColourToken)
					featurePortrayal:AddInstructions('LineInstruction:_simple_')
				end
			elseif lightSector.directionalCharacter then
				-- Directional light.
				local orientation = flipSector(lightSector.directionalCharacter.orientation.orientationValue:ToNumber())
				local leglen = nmi2metres(valueOfNominalRange)

				featurePortrayal:AddInstructions('AugmentedRay:GeographicCRS,' .. orientation .. ',GeographicCRS,' .. leglen)
				featurePortrayal:SimpleLineStyle('dash',0.32,'CHBLK')
				featurePortrayal:AddInstructions('LineInstruction:_simple_')

				local categoryOfLight = feature.categoryOfLight

				if valueOfNominalRange >= 10.0 and not contains(feature.categoryOfLight, { 5 }) and sectorCharacteristic.lightCharacteristic ~= 12 then
					featurePortrayal:AddInstructions('ArcByRadius:0,0,25,0,360')
					featurePortrayal:AddInstructions('AugmentedPath:LocalCRS,LocalCRS,LocalCRS')

					featurePortrayal:SimpleLineStyle('solid',1.28,'OUTLW')
					featurePortrayal:AddInstructions('LineInstruction:_simple_')
					featurePortrayal:SimpleLineStyle('solid',0.64,sectorColourToken)
					featurePortrayal:AddInstructions('LineInstruction:_simple_')
				else
					featurePortrayal:AddInstructions('Rotation:GeographicCRS,' .. orientation)
					featurePortrayal:AddInstructions('ClearGeometry;PointInstruction:' .. sectorLightSymbol)
					featurePortrayal:AddInstructions('Rotation:PortrayalCRS,0')
				end

				featurePortrayal:AddInstructions('LocalOffset:10.53,-3.51;TextAlignVertical:Top;FontSize:10;FontColor:CHBLK;ClearGeometry')
				featurePortrayal:AddTextInstruction(string.format('%03.0f deg', lightSector.directionalCharacter.orientation.orientationValue:ToNumber()), 23, 24, 27070, 24)

				local description = LITDSN02(feature.categoryOfLight[1], sectorCharacteristic, colour, feature.height, lightSector.valueOfNominalRange, feature.status)

				featurePortrayal:AddInstructions('TextAlignVertical:Bottom')
				featurePortrayal:AddTextInstruction(EncodeString(description), 23, 24, 27070, 24)
			else
				-- Neither sectorLimit nor directionalCharacter was found.
				featurePortrayal:AddInstructions('ClearGeometry;PointInstruction:QUESMRK1')
			end
		end
	end

	return 27070
end
