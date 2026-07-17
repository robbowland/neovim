; extends

((string
  ["\"" "'"] @micrographics.punctuation)
  (#set! priority 110))

((template_string
  "`" @micrographics.punctuation)
  (#set! priority 110))
