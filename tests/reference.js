function uitest_reference_codes() {
  throw new Error("The receiver reference test requires native X11.");
}

io_eff(CID(codes), uitest_reference_codes);

function uitest_reference_arrange() {
  throw new Error("Window arrangement requires native X11.");
}

io_eff(CID(arrange), uitest_reference_arrange);

function uitest_reference_snapshot() {
  throw new Error("Input state observation requires native X11.");
}

io_eff(CID(snapshot), uitest_reference_snapshot);
