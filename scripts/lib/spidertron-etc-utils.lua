local SpidertronEtcUtils = {}

SpidertronEtcUtils.container_input_vertical_name = "spidertron-etc-input-vertical"
SpidertronEtcUtils.container_output_vertical_name = "spidertron-etc-output-vertical"
SpidertronEtcUtils.container_input_horizontal_name = "spidertron-etc-input-horizontal"
SpidertronEtcUtils.container_output_horizontal_name = "spidertron-etc-output-horizontal"

function SpidertronEtcUtils.getInputContainerName(direction)
    return (direction % 2 == 0) and
      SpidertronEtcUtils.container_input_vertical_name or
      SpidertronEtcUtils.container_input_horizontal_name
end

function SpidertronEtcUtils.getOutputContainerName(direction)
    return (direction % 2 == 0) and
      SpidertronEtcUtils.container_output_vertical_name or
      SpidertronEtcUtils.container_output_horizontal_name
end

return SpidertronEtcUtils