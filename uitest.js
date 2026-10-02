function uitest_send(ref, events) {
  return { $: CID(Fail), error: io_tup(95,
    "UITest: X11 test effects are unavailable on the JavaScript backend") };
}

function uitest_alive(ref) {
  return { $: CID(Fail), error: io_tup(95,
    "UITest: X11 test effects are unavailable on the JavaScript backend") };
}

io_eff(CID(send), uitest_send);
io_eff(CID(alive), uitest_alive);
