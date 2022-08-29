-- Converter Version: 0.99
-- Feature Catalogue Version: 1.0.0 (2019/4/9)
--
-- ISSUE PSWG #48, PC #111
--
-- Signal Station Traffic main entry point.
function SignalStationTraffic(feature, featurePortrayal, contextParameters)
	local viewingGroup

	-- NOTE: rearranged and not autogenerated for #48 
	viewingGroup = 28020
	if contextParameters.RadarOverlay then
		featurePortrayal:AddInstructions('ViewingGroup:28020;DrawingPriority:21;DisplayPlane:OverRADAR')
	else
		featurePortrayal:AddInstructions('ViewingGroup:28020;DrawingPriority:21;DisplayPlane:UnderRADAR')
	end


	if feature.PrimitiveType == PrimitiveType.Point then
		-- Simplified and paper chart points use the same symbolization
		featurePortrayal:AddInstructions('PointInstruction:2021_SISTAT02_01')
	elseif feature.PrimitiveType == PrimitiveType.Surface then
		-- PSWG #48
		viewingGroup = 28020
		featurePortrayal:AddInstructions('ViewingGroup:28020;DrawingPriority:21;PointInstruction:2021_SISTAT02_01')
	else
		error('Invalid primitive type or mariner settings passed to portrayal')
	end

	return viewingGroup
end
