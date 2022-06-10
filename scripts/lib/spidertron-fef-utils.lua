local SpidertronFefUtils = {}

SpidertronFefUtils.container_input_vertical_name = "spidertron-fef-input-vertical"
SpidertronFefUtils.container_output_vertical_name = "spidertron-fef-output-vertical"
SpidertronFefUtils.container_input_horizontal_name = "spidertron-fef-input-horizontal"
SpidertronFefUtils.container_output_horizontal_name = "spidertron-fef-output-horizontal"

function SpidertronFefUtils.getInputContainerName(direction)
    return (direction % 2 == 0) and
      SpidertronFefUtils.container_input_vertical_name or
      SpidertronFefUtils.container_input_horizontal_name
end

function SpidertronFefUtils.getOutputContainerName(direction)
    return (direction % 2 == 0) and
      SpidertronFefUtils.container_output_vertical_name or
      SpidertronFefUtils.container_output_horizontal_name
end

return SpidertronFefUtils