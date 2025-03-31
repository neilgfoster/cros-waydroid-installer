#include <stdio.h>
#include <stdlib.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>

int main(int argc, char** argv) {
  Window win = strtoul(argv[1], NULL, 16);
  Display *display = XOpenDisplay(getenv("ORIGDISP"));

  XEvent ev;
  ev.xclient.window = win;
  ev.xclient.type = ClientMessage;
  ev.xclient.format = 32;
  ev.xclient.message_type = XInternAtom(display, "_NET_WM_STATE", False);
  ev.xclient.data.l[0] = 1;
  ev.xclient.data.l[1] = XInternAtom(display, "_NET_WM_STATE_FULLSCREEN", False);
  ev.xclient.data.l[2] = 1;

  XSendEvent(display, DefaultRootWindow(display), False, SubstructureRedirectMask | SubstructureNotifyMask, &ev);
  XCloseDisplay(display);
  return 0;
}
