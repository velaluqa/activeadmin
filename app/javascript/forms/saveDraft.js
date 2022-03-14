import React from "react";

export default ({ signingPassword, configurationId }) => {
  return new Promise((resove, reject) => {
    fetch(`/v1/forms/${formId}/answers`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": $("meta[name=csrf-token]").attr("content"),
      },
      body: JSON.stringify({
        form_answer: {
          signing_password: signingPassword,
          configuration_id: configurationId,
          answers: data,
        },
      }),
    })
      .then((response) => response.json())
      .then(({ status, ...rest }) => {
        if (status == 401) {
          setError("Wrong password or corrupt signing key");
          setShowError(true);
        }
        if (status == 200) {
          window.location.replace(
            `/v1/form_answers/${rest.form_answer_id}?message=success`
          );
          resolve;
        }
      });
  });
};
