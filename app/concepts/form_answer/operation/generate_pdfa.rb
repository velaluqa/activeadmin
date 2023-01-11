module FormAnswer::Operation
  class GeneratePdfa < Trailblazer::Operation # :nodoc:
    step :extract_params
    step :load_model
    step :render_html
    step :generate_pdf
    step :convert_to_pdfa
    step :read_pdfa

    def extract_params(ctx, params:, **)
      ctx[:form_answer_id] ||= params[:form_answer_id]
      true
    end

    def load_model(ctx, form_answer_id:, **)
      ctx[:form_answer] = FormAnswer.find(form_answer_id)
      true
    end

    def render_html(ctx, form_answer:, **)
      ctx[:html] = V1::FormAnswersController.new.render_to_string(
        template: "v1/form_answers/pdf.html.erb",
        layout: 'pdf',
        locals: {
          :@title => "Form Answers",
          :@pack_name => "form_answers_show",
          :@component_props => {
            form_answer: form_answer.attributes,
            signature_user: form_answer.public_key.user.attributes,
            form_definition: form_answer.form_definition.attributes,
            form_layout: form_answer.layout
          }.deep_transform_keys { |k| k.to_s.camelize(:lower) }
        }
      )
    end

    def generate_pdf(ctx, html:, **)
      ctx[:pdf] = Grover.new(html).to_pdf
    end

    def convert_to_pdfa(ctx, pdf:, form_answer:, **)
      grover_pdf = Tempfile.open(%w[grover pdf], binmode: true)
      grover_pdf.write(pdf)
      grover_pdf.close

      answers_json = Tempfile.open(%w[answers json])
      answers_json.write(form_answer.answers.to_canonical_json)
      answers_json.close

      signature_txt = Tempfile.open(%w[signature txt])
      signature_txt.write(form_answer.answers_signature)
      signature_txt.close

      public_key = Tempfile.open(%[public_key pub])
      public_key.write(form_answer.public_key.public_key)
      public_key.close

      variables = {
        title: "Form Answers",
        embedded_files: [
          {
            path: answers_json.path,
            filename: "answers.json",
            mimetype: "application/json"
          },
          {
            path: signature_txt.path,
            filename: "signature.base64.txt",
            mimetype: "text/plain"
          },
          {
            path: public_key.path,
            filename: "#{form_answer.public_key.user.username}.id_rsa.pub",
            mimetype: "text/plain"
          }
        ]
      }
      pdfa_ps = Tempfile.new('pdfa.ps')
      pdfa_ps_code =
        ERB
          .new(File.read("/app/vendor/pdfa_attach.ps.erb"))
          .result(OpenStruct.new(variables).instance_eval { binding })
      pdfa_ps.write(pdfa_ps_code)
      pdfa_ps.close

      system(
        [
          "gs",
          "-dNOSAFER",
          "-dPDFA=3",
          "-sColorConversionStrategy=RGB",
          "-sDEVICE=pdfwrite",
          "-dPDFACompatibilityPolicy=1",
          "-dPDFSETTINGS=/default",
          "-dAutoRotatePages=/All",
          "-dNOPAUSE",
          "-dBATCH",
          "-dQUIET",
          "-o #{form_answer.pdfa_path.inspect}",
          pdfa_ps.path.inspect,
          "-f #{grover_pdf.path.inspect}"
        ].join(" ")
      )

      $?.exitstatus == 0
    end

    def read_pdfa(ctx, form_answer:, **)
      ctx[:pdfa] = File.read(form_answer.pdfa_path)
    end
  end
end
