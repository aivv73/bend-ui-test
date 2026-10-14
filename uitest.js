function uitest_send(display, id, events) {
  return { $: CID(Fail), error: io_tup(95,
    "UITest: X11 test effects are unavailable on the JavaScript backend") };
}

function uitest_alive(display, id) {
  return { $: CID(Fail), error: io_tup(95,
    "UITest: X11 test effects are unavailable on the JavaScript backend") };
}

io_eff(CID(send_to), uitest_send);
io_eff(CID(alive_at), uitest_alive);
