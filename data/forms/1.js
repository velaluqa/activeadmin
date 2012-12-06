$(function () {
	   $("input,textarea,select").jqBootstrapValidation(
	   {
		submitError: function($form, event, errors)
		{
			alert(JSON.stringify(PharmTraceAPI, null, 4));

			PharmTraceAPI.updateROIs();
			alert(JSON.stringify(PharmTraceAPI.roiList, null, 4));
		}
	}
	);
});