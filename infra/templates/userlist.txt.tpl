%{ for user in users ~}
"${user.name}" "${user.password}"
%{ endfor ~}