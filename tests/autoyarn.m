// Deterministic tests: synthetic icons exercise the real decoder, colour
// selection, async cache, charts and renderer without any running apps.
#define KNIT_AUTO_TEST 1
#include "../src/autoyarn.m"
#include <stdatomic.h>
#include <stdio.h>

static NSImage* fixture;
static atomic_int samples;
static int ready_count;
static dispatch_semaphore_t gate;

NSImage* knit_test_icon(pid_t pid) {
  assert(!pthread_main_np());
  atomic_fetch_add(&samples, 1);
  if (gate) dispatch_semaphore_wait(gate, DISPATCH_TIME_FOREVER);
  if (pid == 999) return nil;
  return fixture;
}
void knit_auto_yarn_ready(pid_t pid) {
  assert(pthread_main_np());
  assert(pid > 0);
  ready_count++;
}

static NSImage* make_icon(uint32_t first, uint32_t second) {
  uint32_t pixels[48*48];
  for (int i=0;i<48*48;i++) pixels[i] = i%48 < 36 ? first : second;
  CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
  CGContextRef context=CGBitmapContextCreate(pixels,48,48,8,48*4,space,
      kCGImageAlphaPremultipliedFirst|kCGBitmapByteOrder32Host);
  CGColorSpaceRelease(space);
  CGImageRef image=CGBitmapContextCreateImage(context);
  NSImage* result=[[NSImage alloc] initWithCGImage:image size:NSMakeSize(48,48)];
  CGImageRelease(image); CGContextRelease(context);
  return result;
}

static void drain(void) {
  dispatch_sync(g_auto_queue, ^{});
  CFAbsoluteTime deadline=CFAbsoluteTimeGetCurrent()+3;
  for (;;) {
    bool pending=false;
    for(int i=0;i<g_auto_count;i++) pending |= g_auto[i].pending;
    if (!pending) break;
    assert(CFAbsoluteTimeGetCurrent()<deadline);
    CFRunLoopRunInMode(kCFRunLoopDefaultMode,0.005,false);
  }
}

static int request(const char* name, pid_t pid, uint32_t* yarn) {
  int chart=-2;
  if (!knit_auto_yarn(name,pid,yarn,&chart)) {
    drain();
    assert(knit_auto_yarn(name,pid,yarn,&chart));
  }
  return chart;
}

static void check_chart(int index, uint32_t contrast) {
  assert(index>=0 && index<g_chart_count);
  struct knit_chart* c=&g_charts[index];
  assert(c->generated);
  bool base=false, motif=false;
  for(int i=0;i<c->w*c->h;i++) {
    assert(c->px[i]==0 || c->px[i]==contrast);
    base |= c->px[i]==0; motif |= c->px[i]==contrast;
  }
  assert(base && motif);
}

int main(void) { @autoreleasepool {
  knit_charts_load(NULL); // no personal configuration or custom files
  int builtins=g_chart_count;
  uint32_t base=0,contrast=0;
  assert(!icon_pixels(nil,&base,&contrast));
  assert(!icon_pixels(make_icon(0xff888888,0xffffffff),&base,&contrast));
  assert(!icon_pixels(make_icon(0x00000000,0x00000000),&base,&contrast));
  assert(!icon_pixels(make_icon(0xcc990000,0xcc990000),&base,&contrast));
  assert(icon_pixels(make_icon(0xffff0000,0xffff0000),&base,&contrast));
  assert(contrast==0xfff6f0de);
  uint32_t opaque_base=base;
  assert(icon_pixels(make_icon(0xeeee0000,0xeeee0000),&base,&contrast));
  // Unpremultiplication restores the same histogram bin for these samples.
  assert(base==opaque_base);
  assert(icon_pixels(make_icon(0xffaaffaa,0xffaaffaa),&base,&contrast));
  double h,s,l,h2,s2,l2;
  rgb2hsl(base,&h,&s,&l); rgb2hsl(contrast,&h2,&s2,&l2);
  assert(l>l2 && l-l2>=0.20);
  // A diverse grid catches lightness compression and dark/light clamp edges.
  for(int r=17;r<256;r+=34) for(int g=17;g<256;g+=34) for(int b=17;b<256;b+=34) {
    uint32_t color=0xff000000u|(r<<16)|(g<<8)|b;
    if (!icon_pixels(make_icon(color,0xff113377),&base,&contrast)) continue;
    rgb2hsl(base,&h,&s,&l); rgb2hsl(contrast,&h2,&s2,&l2);
    assert(fabs(l-l2)>=0.195); // byte quantization allows half a percent
    assert(s<=0.61 && l>=0.29 && l<=0.73);
  }
  puts("PASS: real icon decoding, alpha/neutral filters, softened palettes and visible final contrast");

  fixture=make_icon(0xff3377dd,0xffffffff);
  uint32_t yarn=0x12345678; int chart=123;
  const char* invalid[]={NULL,"","Finder","Claude","Notion"};
  for(size_t i=0;i<sizeof invalid/sizeof *invalid;i++)
    assert(!knit_auto_yarn(invalid[i],42,&yarn,&chart));
  assert(!knit_auto_yarn("Example",0,&yarn,&chart));
  assert(!knit_auto_yarn("Example",42,NULL,&chart));
  assert(!knit_auto_yarn("Example",42,&yarn,NULL));
  char long_name[128]; memset(long_name,'a',127);long_name[127]=0;
  assert(!knit_auto_yarn(long_name,42,&yarn,&chart));
  assert(yarn==0x12345678 && chart==123 && atomic_load(&samples)==0);
  g_app_rule_count=1;
  snprintf(g_app_rules[0].match,sizeof g_app_rules[0].match,"Personal");
  assert(!knit_auto_yarn("Personal App",42,&yarn,&chart));
  g_app_rule_count=0;

  // A deliberately blocked decoder must not stall a draw or duplicate work.
  gate=dispatch_semaphore_create(0);
  CFAbsoluteTime began=CFAbsoluteTimeGetCurrent();
  assert(!knit_auto_yarn("Example",42,&yarn,&chart));
  assert(!knit_auto_yarn("Example",42,&yarn,&chart));
  assert(CFAbsoluteTimeGetCurrent()-began<0.1);
  assert(yarn==0x12345678 && chart==123);
  dispatch_semaphore_signal(gate); drain(); gate=nil;
  assert(atomic_load(&samples)==1 && ready_count==1);
  chart=request("Example",42,&yarn);
  check_chart(chart,g_auto[0].contrast);
  uint32_t first=yarn; int first_chart=chart;
  for(int i=0;i<10000;i++) {
    assert(knit_auto_yarn("Example",42,&yarn,&chart));
    assert(yarn==first && chart==first_chart);
  }
  assert(atomic_load(&samples)==1);
  puts("PASS: authored/user rules, invalid inputs, nonblocking sampling, deduplication and cache hits");

  g_knit_pattern_by_app=false;
  assert(knit_auto_yarn("Example",42,&yarn,&chart) && chart==-1 && yarn==first);
  g_knit_pattern_by_app=true;
  assert(knit_auto_yarn("Example",42,&yarn,&chart) && chart==first_chart);
  g_knit_pattern_by_app=false;
  int count=g_chart_count;
  assert(request("Global first",43,&yarn)==-1 && g_chart_count==count);
  g_knit_pattern_by_app=true;
  assert(request("Global first",43,&yarn)>=0);
  // Reload, then generate in reverse order so stale indexes cannot pass.
  knit_charts_load(NULL); knit_flush_cache();
  assert(request("Global first",43,&yarn)==builtins);
  assert(request("Example",42,&yarn)==builtins+1 && yarn==first);
  check_chart(builtins+1,g_auto[0].contrast);
  assert(atomic_load(&samples)==2);
  puts("PASS: global/plain/By App transitions in both directions and reload with reordered chart indexes");

  // Missing icons can recover; neutral icons are sampled once per process.
  assert(!knit_auto_yarn("Launching",999,&yarn,&chart)); drain();
  int calls=atomic_load(&samples);
  assert(!knit_auto_yarn("Launching",999,&yarn,&chart));
  assert(atomic_load(&samples)==calls);
  g_auto[2].retry_after=0;
  assert(!knit_auto_yarn("Launching",999,&yarn,&chart));drain();
  assert(atomic_load(&samples)==calls+1);
  fixture=make_icon(0xff999999,0xffffffff);
  assert(!knit_auto_yarn("Grey",50,&yarn,&chart));drain();
  calls=atomic_load(&samples);
  assert(!knit_auto_yarn("Grey",50,&yarn,&chart));
  assert(atomic_load(&samples)==calls);
  fixture=make_icon(0xffdd7733,0xffffffff);
  assert(request("Grey",51,&yarn)>=0); // relaunched process has a fresh cache
  puts("PASS: missing-icon retry, negative caching and resampling after app relaunch");

  for(int i=0;i<160;i++) {
    char name[64];snprintf(name,sizeof name,"Unsupported %d",i);
    assert(request(name,1000+i,&yarn)>=0);
  }
  assert(g_auto_count==KNIT_AUTO_MAX);
  assert(g_chart_count<=builtins+KNIT_AUTO_MAX);
  // No retained chart accidentally contains a literal source-pattern colour.
  for(int i=0;i<g_auto_count;i++) if(g_auto[i].ok)
    check_chart(g_auto[i].chart,g_auto[i].contrast);
  puts("PASS: 160 apps cycle through bounded cache without exhausting the generated chart table");

  // Mode and chart generation can change while a decode is still in flight.
  gate=dispatch_semaphore_create(0);
  assert(!knit_auto_yarn("In flight",700,&yarn,&chart));
  knit_charts_load(NULL);knit_flush_cache();
  g_knit_pattern_by_app=false;
  dispatch_semaphore_signal(gate);drain();gate=nil;
  assert(request("In flight",700,&yarn)==-1);
  g_knit_pattern_by_app=true;
  assert(request("In flight",700,&yarn)>=0);
  // An authored override added during decoding still takes precedence.
  assert(!knit_auto_yarn("New personal",701,&yarn,&chart));
  g_app_rule_count=1;
  snprintf(g_app_rules[0].match,sizeof g_app_rules[0].match,"New personal");
  drain();
  assert(!knit_auto_yarn("New personal",701,&yarn,&chart));
  g_app_rule_count=0;
  assert(request("New personal",701,&yarn)>=0);
  puts("PASS: mode/reload/rule changes while icon work is in flight");

  // Full custom-chart table gracefully keeps the colour; reload restores motif.
  knit_charts_load(NULL);knit_flush_cache();
  g_chart_count=KNIT_CHART_MAX;
  assert(request("Table full",800,&yarn)==-1);
  knit_charts_load(NULL);knit_flush_cache();
  assert(request("Table full",800,&yarn)>=0);
  puts("PASS: chart-capacity fallback and recovery after reload");
  return 0;
}}
