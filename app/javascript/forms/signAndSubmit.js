export default ({ signingPassword, formAnswerId, answers }) => {
  return new Promise((resolve, reject) => {
    fetch(`/v1/form_answers/${formAnswerId}/sign`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": $("meta[name=csrf-token]").attr("content"),
      },
      body: JSON.stringify({
        form_answer: {
          signing_password: signingPassword,
          answers,
        },
      }),
    })
      .then((response) => response.json())
      .then(({ status, ...response }) => {
        if (status == 401) {
          reject("Wrong password or corrupt signing key");
        }
        if (status == 200) resolve(response);
      });
  });
};
