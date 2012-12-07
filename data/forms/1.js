function validate_foobar($form)
{
	var reader_name = $form.find("input[name=reader_name]").val()

	if(reader_name != "Hans")
	{
		return ["Why you no named Hans?!?"];
	}

	return [];
}
function validate_barfoo($form)
{
	var reader_age = $form.find("input[name=reader_age]").val()

	if(reader_age != 42)
	{
		return ["Your age is just wrong!"];
	}

	return [];	
}

window.register_custom_validation_function(validate_foobar);
window.register_custom_validation_function(validate_barfoo);
