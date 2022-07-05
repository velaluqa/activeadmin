$(function () {
  var backgroundJobBody = $("body.admin_background_jobs");

  if (backgroundJobBody.length > 0) {
    App.messages = App.cable.subscriptions.create("BackgroundJobsChannel", {
      connected: function () {},

      received: function (data) {
        var $state = $("#background_job_state_" + data.job_id);

        if ($state.length == 0) return;

        var updatedAtOnPage = Date.parse($state.data("updated-at"));
        var updatedAtInMessage = Date.parse(data.updated_at);

        if (updatedAtOnPage < updatedAtInMessage) {
          if (data.finished) {
            location.reload();
          } else {
            $("#background_job_state_" + data.job_id).replaceWith(data.html);
          }
        }
      },
    });
  }
});
