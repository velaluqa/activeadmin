function hasPharmTraceAPI()
{
	return (typeof PharmTraceAPI != 'undefined');
}

$(document).ready(function()
{
	if(typeof PharmTraceAPI != 'undefined')
	{
		console.log("PharmTrace API availale");
	}
	else
	{
		console.log("ERROR: PharmTrace API not available, form will not be fully functional!");
	}
});

$(function () {
	   $("input,textarea,select").jqBootstrapValidation(
	   {
		submitError: function($form, event, errors)
		{
			if(!hasPharmTraceAPI()) { alert("test"); return; }
			
			PharmTraceAPI.updateROIs();

			rois = PharmTraceAPI.rois;
			alert(rois.constructor.name);
			alert(rois.length);

			for(var i = 0; i < rois.length; i++)
			{
				for(var key in rois[i])
				{
					alert(key+ ": "+rois[i][key]);
				}
			}
		}
	}
	);
});