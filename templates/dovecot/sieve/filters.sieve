require ["fileinto"];
if header :contains "Subject" "Newsletter" {
  fileinto "Newsletter";
}

if address :is "from" "geronimo@vagrant-dummy-ops.lab" {
  fileinto "Work";
}

if header :contains "Subject" ["buy","order"] {
  redirect "daisy@dovecot.vagrant-dummy-ops.lab";
}
