require ["reject"];

if anyof (header :contains "Subject" "Violence",
          header :contains "Subject" "Crime") {
  reject "Message rejected by system policy.";
}
