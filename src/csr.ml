open Cmdliner
open Common

let org =
  let doc = "Organization name for the certificate signing request." in
  Arg.(required & pos ~rev:false 1 (some string) None & info [] ~doc ~docv:"O")

let certfile =
  let doc = "Filename to which to save the completed certificate-signing request." in
  Arg.(value & opt string "csr.pem" & info ["c"; "certificate"; "csr"; "out"] ~doc)

let csr org cn length certfile keyfile =
  Nocrypto_entropy_unix.initialize ();
  let privkey = `RSA (Nocrypto.Rsa.generate length) in
  let dn = [ `CN cn ; `O org ] in
  let csr = X509.CA.request dn privkey in
  let csr_pem = X509.CA.encode_pem csr in
  let key_pem = X509.Private_key.encode_pem privkey in
  match (write_pem certfile csr_pem, write_pem keyfile key_pem) with
  | Ok (), Ok () -> Ok ()
  | Error str, _ | _, Error str -> Error str

let csr_t = Term.(term_result (pure csr $ org $ common_name $ length $ certfile $ keyfile))

let csr_info =
  let doc = "generate a certificate-signing request" in
  let man = [ `S "BUGS";
              `P "Submit bugs at https://github.com/yomimono/ocaml-certify";] in
  Term.info "csr" ~doc ~man

let () = Term.(exit @@ eval (csr_t, csr_info))
