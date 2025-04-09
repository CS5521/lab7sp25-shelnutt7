
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4                   	.byte 0xe4

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 30 c6 10 80       	mov    $0x8010c630,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 74 37 10 80       	mov    $0x80103774,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 64 84 10 	movl   $0x80108464,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 40 c6 10 80 	movl   $0x8010c640,(%esp)
80100049:	e8 71 4f 00 00       	call   80104fbf <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 8c 0d 11 80 3c 	movl   $0x80110d3c,0x80110d8c
80100055:	0d 11 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 90 0d 11 80 3c 	movl   $0x80110d3c,0x80110d90
8010005f:	0d 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 74 c6 10 80 	movl   $0x8010c674,-0xc(%ebp)
80100069:	eb 46                	jmp    801000b1 <binit+0x7d>
    b->next = bcache.head.next;
8010006b:	8b 15 90 0d 11 80    	mov    0x80110d90,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 54             	mov    %edx,0x54(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 50 3c 0d 11 80 	movl   $0x80110d3c,0x50(%eax)
    initsleeplock(&b->lock, "buffer");
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	83 c0 0c             	add    $0xc,%eax
80100087:	c7 44 24 04 6b 84 10 	movl   $0x8010846b,0x4(%esp)
8010008e:	80 
8010008f:	89 04 24             	mov    %eax,(%esp)
80100092:	e8 c5 4d 00 00       	call   80104e5c <initsleeplock>
    bcache.head.next->prev = b;
80100097:	a1 90 0d 11 80       	mov    0x80110d90,%eax
8010009c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010009f:	89 50 50             	mov    %edx,0x50(%eax)
    bcache.head.next = b;
801000a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000a5:	a3 90 0d 11 80       	mov    %eax,0x80110d90
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
801000aa:	81 45 f4 5c 02 00 00 	addl   $0x25c,-0xc(%ebp)
801000b1:	81 7d f4 3c 0d 11 80 	cmpl   $0x80110d3c,-0xc(%ebp)
801000b8:	72 b1                	jb     8010006b <binit+0x37>
  }
}
801000ba:	c9                   	leave  
801000bb:	c3                   	ret    

801000bc <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
801000bc:	55                   	push   %ebp
801000bd:	89 e5                	mov    %esp,%ebp
801000bf:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000c2:	c7 04 24 40 c6 10 80 	movl   $0x8010c640,(%esp)
801000c9:	e8 12 4f 00 00       	call   80104fe0 <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000ce:	a1 90 0d 11 80       	mov    0x80110d90,%eax
801000d3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000d6:	eb 50                	jmp    80100128 <bget+0x6c>
    if(b->dev == dev && b->blockno == blockno){
801000d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000db:	8b 40 04             	mov    0x4(%eax),%eax
801000de:	3b 45 08             	cmp    0x8(%ebp),%eax
801000e1:	75 3c                	jne    8010011f <bget+0x63>
801000e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e6:	8b 40 08             	mov    0x8(%eax),%eax
801000e9:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000ec:	75 31                	jne    8010011f <bget+0x63>
      b->refcnt++;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 40 4c             	mov    0x4c(%eax),%eax
801000f4:	8d 50 01             	lea    0x1(%eax),%edx
801000f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fa:	89 50 4c             	mov    %edx,0x4c(%eax)
      release(&bcache.lock);
801000fd:	c7 04 24 40 c6 10 80 	movl   $0x8010c640,(%esp)
80100104:	e8 3f 4f 00 00       	call   80105048 <release>
      acquiresleep(&b->lock);
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	83 c0 0c             	add    $0xc,%eax
8010010f:	89 04 24             	mov    %eax,(%esp)
80100112:	e8 7f 4d 00 00       	call   80104e96 <acquiresleep>
      return b;
80100117:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011a:	e9 94 00 00 00       	jmp    801001b3 <bget+0xf7>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010011f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100122:	8b 40 54             	mov    0x54(%eax),%eax
80100125:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100128:	81 7d f4 3c 0d 11 80 	cmpl   $0x80110d3c,-0xc(%ebp)
8010012f:	75 a7                	jne    801000d8 <bget+0x1c>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100131:	a1 8c 0d 11 80       	mov    0x80110d8c,%eax
80100136:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100139:	eb 63                	jmp    8010019e <bget+0xe2>
    if(b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
8010013b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010013e:	8b 40 4c             	mov    0x4c(%eax),%eax
80100141:	85 c0                	test   %eax,%eax
80100143:	75 50                	jne    80100195 <bget+0xd9>
80100145:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100148:	8b 00                	mov    (%eax),%eax
8010014a:	83 e0 04             	and    $0x4,%eax
8010014d:	85 c0                	test   %eax,%eax
8010014f:	75 44                	jne    80100195 <bget+0xd9>
      b->dev = dev;
80100151:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100154:	8b 55 08             	mov    0x8(%ebp),%edx
80100157:	89 50 04             	mov    %edx,0x4(%eax)
      b->blockno = blockno;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 0c             	mov    0xc(%ebp),%edx
80100160:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = 0;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      b->refcnt = 1;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 40 4c 01 00 00 00 	movl   $0x1,0x4c(%eax)
      release(&bcache.lock);
80100176:	c7 04 24 40 c6 10 80 	movl   $0x8010c640,(%esp)
8010017d:	e8 c6 4e 00 00       	call   80105048 <release>
      acquiresleep(&b->lock);
80100182:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100185:	83 c0 0c             	add    $0xc,%eax
80100188:	89 04 24             	mov    %eax,(%esp)
8010018b:	e8 06 4d 00 00       	call   80104e96 <acquiresleep>
      return b;
80100190:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100193:	eb 1e                	jmp    801001b3 <bget+0xf7>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100195:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100198:	8b 40 50             	mov    0x50(%eax),%eax
8010019b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010019e:	81 7d f4 3c 0d 11 80 	cmpl   $0x80110d3c,-0xc(%ebp)
801001a5:	75 94                	jne    8010013b <bget+0x7f>
    }
  }
  panic("bget: no buffers");
801001a7:	c7 04 24 72 84 10 80 	movl   $0x80108472,(%esp)
801001ae:	e8 af 03 00 00       	call   80100562 <panic>
}
801001b3:	c9                   	leave  
801001b4:	c3                   	ret    

801001b5 <bread>:

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
801001b5:	55                   	push   %ebp
801001b6:	89 e5                	mov    %esp,%ebp
801001b8:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, blockno);
801001bb:	8b 45 0c             	mov    0xc(%ebp),%eax
801001be:	89 44 24 04          	mov    %eax,0x4(%esp)
801001c2:	8b 45 08             	mov    0x8(%ebp),%eax
801001c5:	89 04 24             	mov    %eax,(%esp)
801001c8:	e8 ef fe ff ff       	call   801000bc <bget>
801001cd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((b->flags & B_VALID) == 0) {
801001d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d3:	8b 00                	mov    (%eax),%eax
801001d5:	83 e0 02             	and    $0x2,%eax
801001d8:	85 c0                	test   %eax,%eax
801001da:	75 0b                	jne    801001e7 <bread+0x32>
    iderw(b);
801001dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001df:	89 04 24             	mov    %eax,(%esp)
801001e2:	e8 a4 26 00 00       	call   8010288b <iderw>
  }
  return b;
801001e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001ea:	c9                   	leave  
801001eb:	c3                   	ret    

801001ec <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
801001ec:	55                   	push   %ebp
801001ed:	89 e5                	mov    %esp,%ebp
801001ef:	83 ec 18             	sub    $0x18,%esp
  if(!holdingsleep(&b->lock))
801001f2:	8b 45 08             	mov    0x8(%ebp),%eax
801001f5:	83 c0 0c             	add    $0xc,%eax
801001f8:	89 04 24             	mov    %eax,(%esp)
801001fb:	e8 33 4d 00 00       	call   80104f33 <holdingsleep>
80100200:	85 c0                	test   %eax,%eax
80100202:	75 0c                	jne    80100210 <bwrite+0x24>
    panic("bwrite");
80100204:	c7 04 24 83 84 10 80 	movl   $0x80108483,(%esp)
8010020b:	e8 52 03 00 00       	call   80100562 <panic>
  b->flags |= B_DIRTY;
80100210:	8b 45 08             	mov    0x8(%ebp),%eax
80100213:	8b 00                	mov    (%eax),%eax
80100215:	83 c8 04             	or     $0x4,%eax
80100218:	89 c2                	mov    %eax,%edx
8010021a:	8b 45 08             	mov    0x8(%ebp),%eax
8010021d:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010021f:	8b 45 08             	mov    0x8(%ebp),%eax
80100222:	89 04 24             	mov    %eax,(%esp)
80100225:	e8 61 26 00 00       	call   8010288b <iderw>
}
8010022a:	c9                   	leave  
8010022b:	c3                   	ret    

8010022c <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
8010022c:	55                   	push   %ebp
8010022d:	89 e5                	mov    %esp,%ebp
8010022f:	83 ec 18             	sub    $0x18,%esp
  if(!holdingsleep(&b->lock))
80100232:	8b 45 08             	mov    0x8(%ebp),%eax
80100235:	83 c0 0c             	add    $0xc,%eax
80100238:	89 04 24             	mov    %eax,(%esp)
8010023b:	e8 f3 4c 00 00       	call   80104f33 <holdingsleep>
80100240:	85 c0                	test   %eax,%eax
80100242:	75 0c                	jne    80100250 <brelse+0x24>
    panic("brelse");
80100244:	c7 04 24 8a 84 10 80 	movl   $0x8010848a,(%esp)
8010024b:	e8 12 03 00 00       	call   80100562 <panic>

  releasesleep(&b->lock);
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	83 c0 0c             	add    $0xc,%eax
80100256:	89 04 24             	mov    %eax,(%esp)
80100259:	e8 93 4c 00 00       	call   80104ef1 <releasesleep>

  acquire(&bcache.lock);
8010025e:	c7 04 24 40 c6 10 80 	movl   $0x8010c640,(%esp)
80100265:	e8 76 4d 00 00       	call   80104fe0 <acquire>
  b->refcnt--;
8010026a:	8b 45 08             	mov    0x8(%ebp),%eax
8010026d:	8b 40 4c             	mov    0x4c(%eax),%eax
80100270:	8d 50 ff             	lea    -0x1(%eax),%edx
80100273:	8b 45 08             	mov    0x8(%ebp),%eax
80100276:	89 50 4c             	mov    %edx,0x4c(%eax)
  if (b->refcnt == 0) {
80100279:	8b 45 08             	mov    0x8(%ebp),%eax
8010027c:	8b 40 4c             	mov    0x4c(%eax),%eax
8010027f:	85 c0                	test   %eax,%eax
80100281:	75 47                	jne    801002ca <brelse+0x9e>
    // no one is waiting for it.
    b->next->prev = b->prev;
80100283:	8b 45 08             	mov    0x8(%ebp),%eax
80100286:	8b 40 54             	mov    0x54(%eax),%eax
80100289:	8b 55 08             	mov    0x8(%ebp),%edx
8010028c:	8b 52 50             	mov    0x50(%edx),%edx
8010028f:	89 50 50             	mov    %edx,0x50(%eax)
    b->prev->next = b->next;
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	8b 40 50             	mov    0x50(%eax),%eax
80100298:	8b 55 08             	mov    0x8(%ebp),%edx
8010029b:	8b 52 54             	mov    0x54(%edx),%edx
8010029e:	89 50 54             	mov    %edx,0x54(%eax)
    b->next = bcache.head.next;
801002a1:	8b 15 90 0d 11 80    	mov    0x80110d90,%edx
801002a7:	8b 45 08             	mov    0x8(%ebp),%eax
801002aa:	89 50 54             	mov    %edx,0x54(%eax)
    b->prev = &bcache.head;
801002ad:	8b 45 08             	mov    0x8(%ebp),%eax
801002b0:	c7 40 50 3c 0d 11 80 	movl   $0x80110d3c,0x50(%eax)
    bcache.head.next->prev = b;
801002b7:	a1 90 0d 11 80       	mov    0x80110d90,%eax
801002bc:	8b 55 08             	mov    0x8(%ebp),%edx
801002bf:	89 50 50             	mov    %edx,0x50(%eax)
    bcache.head.next = b;
801002c2:	8b 45 08             	mov    0x8(%ebp),%eax
801002c5:	a3 90 0d 11 80       	mov    %eax,0x80110d90
  }
  
  release(&bcache.lock);
801002ca:	c7 04 24 40 c6 10 80 	movl   $0x8010c640,(%esp)
801002d1:	e8 72 4d 00 00       	call   80105048 <release>
}
801002d6:	c9                   	leave  
801002d7:	c3                   	ret    

801002d8 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002d8:	55                   	push   %ebp
801002d9:	89 e5                	mov    %esp,%ebp
801002db:	83 ec 14             	sub    $0x14,%esp
801002de:	8b 45 08             	mov    0x8(%ebp),%eax
801002e1:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002e5:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801002e9:	89 c2                	mov    %eax,%edx
801002eb:	ec                   	in     (%dx),%al
801002ec:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801002ef:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801002f3:	c9                   	leave  
801002f4:	c3                   	ret    

801002f5 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002f5:	55                   	push   %ebp
801002f6:	89 e5                	mov    %esp,%ebp
801002f8:	83 ec 08             	sub    $0x8,%esp
801002fb:	8b 55 08             	mov    0x8(%ebp),%edx
801002fe:	8b 45 0c             	mov    0xc(%ebp),%eax
80100301:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80100305:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80100308:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010030c:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80100310:	ee                   	out    %al,(%dx)
}
80100311:	c9                   	leave  
80100312:	c3                   	ret    

80100313 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80100313:	55                   	push   %ebp
80100314:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80100316:	fa                   	cli    
}
80100317:	5d                   	pop    %ebp
80100318:	c3                   	ret    

80100319 <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
80100319:	55                   	push   %ebp
8010031a:	89 e5                	mov    %esp,%ebp
8010031c:	56                   	push   %esi
8010031d:	53                   	push   %ebx
8010031e:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
80100321:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100325:	74 1c                	je     80100343 <printint+0x2a>
80100327:	8b 45 08             	mov    0x8(%ebp),%eax
8010032a:	c1 e8 1f             	shr    $0x1f,%eax
8010032d:	0f b6 c0             	movzbl %al,%eax
80100330:	89 45 10             	mov    %eax,0x10(%ebp)
80100333:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100337:	74 0a                	je     80100343 <printint+0x2a>
    x = -xx;
80100339:	8b 45 08             	mov    0x8(%ebp),%eax
8010033c:	f7 d8                	neg    %eax
8010033e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100341:	eb 06                	jmp    80100349 <printint+0x30>
  else
    x = xx;
80100343:	8b 45 08             	mov    0x8(%ebp),%eax
80100346:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100349:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100350:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80100353:	8d 41 01             	lea    0x1(%ecx),%eax
80100356:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100359:	8b 5d 0c             	mov    0xc(%ebp),%ebx
8010035c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010035f:	ba 00 00 00 00       	mov    $0x0,%edx
80100364:	f7 f3                	div    %ebx
80100366:	89 d0                	mov    %edx,%eax
80100368:	0f b6 80 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%eax
8010036f:	88 44 0d e0          	mov    %al,-0x20(%ebp,%ecx,1)
  }while((x /= base) != 0);
80100373:	8b 75 0c             	mov    0xc(%ebp),%esi
80100376:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100379:	ba 00 00 00 00       	mov    $0x0,%edx
8010037e:	f7 f6                	div    %esi
80100380:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100383:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80100387:	75 c7                	jne    80100350 <printint+0x37>

  if(sign)
80100389:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010038d:	74 10                	je     8010039f <printint+0x86>
    buf[i++] = '-';
8010038f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100392:	8d 50 01             	lea    0x1(%eax),%edx
80100395:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100398:	c6 44 05 e0 2d       	movb   $0x2d,-0x20(%ebp,%eax,1)

  while(--i >= 0)
8010039d:	eb 18                	jmp    801003b7 <printint+0x9e>
8010039f:	eb 16                	jmp    801003b7 <printint+0x9e>
    consputc(buf[i]);
801003a1:	8d 55 e0             	lea    -0x20(%ebp),%edx
801003a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801003a7:	01 d0                	add    %edx,%eax
801003a9:	0f b6 00             	movzbl (%eax),%eax
801003ac:	0f be c0             	movsbl %al,%eax
801003af:	89 04 24             	mov    %eax,(%esp)
801003b2:	e8 d5 03 00 00       	call   8010078c <consputc>
  while(--i >= 0)
801003b7:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
801003bb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801003bf:	79 e0                	jns    801003a1 <printint+0x88>
}
801003c1:	83 c4 30             	add    $0x30,%esp
801003c4:	5b                   	pop    %ebx
801003c5:	5e                   	pop    %esi
801003c6:	5d                   	pop    %ebp
801003c7:	c3                   	ret    

801003c8 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003c8:	55                   	push   %ebp
801003c9:	89 e5                	mov    %esp,%ebp
801003cb:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003ce:	a1 d4 b5 10 80       	mov    0x8010b5d4,%eax
801003d3:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003d6:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003da:	74 0c                	je     801003e8 <cprintf+0x20>
    acquire(&cons.lock);
801003dc:	c7 04 24 a0 b5 10 80 	movl   $0x8010b5a0,(%esp)
801003e3:	e8 f8 4b 00 00       	call   80104fe0 <acquire>

  if (fmt == 0)
801003e8:	8b 45 08             	mov    0x8(%ebp),%eax
801003eb:	85 c0                	test   %eax,%eax
801003ed:	75 0c                	jne    801003fb <cprintf+0x33>
    panic("null fmt");
801003ef:	c7 04 24 91 84 10 80 	movl   $0x80108491,(%esp)
801003f6:	e8 67 01 00 00       	call   80100562 <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003fb:	8d 45 0c             	lea    0xc(%ebp),%eax
801003fe:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100401:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100408:	e9 21 01 00 00       	jmp    8010052e <cprintf+0x166>
    if(c != '%'){
8010040d:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
80100411:	74 10                	je     80100423 <cprintf+0x5b>
      consputc(c);
80100413:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100416:	89 04 24             	mov    %eax,(%esp)
80100419:	e8 6e 03 00 00       	call   8010078c <consputc>
      continue;
8010041e:	e9 07 01 00 00       	jmp    8010052a <cprintf+0x162>
    }
    c = fmt[++i] & 0xff;
80100423:	8b 55 08             	mov    0x8(%ebp),%edx
80100426:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010042a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010042d:	01 d0                	add    %edx,%eax
8010042f:	0f b6 00             	movzbl (%eax),%eax
80100432:	0f be c0             	movsbl %al,%eax
80100435:	25 ff 00 00 00       	and    $0xff,%eax
8010043a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
8010043d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100441:	75 05                	jne    80100448 <cprintf+0x80>
      break;
80100443:	e9 06 01 00 00       	jmp    8010054e <cprintf+0x186>
    switch(c){
80100448:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010044b:	83 f8 70             	cmp    $0x70,%eax
8010044e:	74 4f                	je     8010049f <cprintf+0xd7>
80100450:	83 f8 70             	cmp    $0x70,%eax
80100453:	7f 13                	jg     80100468 <cprintf+0xa0>
80100455:	83 f8 25             	cmp    $0x25,%eax
80100458:	0f 84 a6 00 00 00    	je     80100504 <cprintf+0x13c>
8010045e:	83 f8 64             	cmp    $0x64,%eax
80100461:	74 14                	je     80100477 <cprintf+0xaf>
80100463:	e9 aa 00 00 00       	jmp    80100512 <cprintf+0x14a>
80100468:	83 f8 73             	cmp    $0x73,%eax
8010046b:	74 57                	je     801004c4 <cprintf+0xfc>
8010046d:	83 f8 78             	cmp    $0x78,%eax
80100470:	74 2d                	je     8010049f <cprintf+0xd7>
80100472:	e9 9b 00 00 00       	jmp    80100512 <cprintf+0x14a>
    case 'd':
      printint(*argp++, 10, 1);
80100477:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010047a:	8d 50 04             	lea    0x4(%eax),%edx
8010047d:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100480:	8b 00                	mov    (%eax),%eax
80100482:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80100489:	00 
8010048a:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100491:	00 
80100492:	89 04 24             	mov    %eax,(%esp)
80100495:	e8 7f fe ff ff       	call   80100319 <printint>
      break;
8010049a:	e9 8b 00 00 00       	jmp    8010052a <cprintf+0x162>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
8010049f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801004a2:	8d 50 04             	lea    0x4(%eax),%edx
801004a5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004a8:	8b 00                	mov    (%eax),%eax
801004aa:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801004b1:	00 
801004b2:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
801004b9:	00 
801004ba:	89 04 24             	mov    %eax,(%esp)
801004bd:	e8 57 fe ff ff       	call   80100319 <printint>
      break;
801004c2:	eb 66                	jmp    8010052a <cprintf+0x162>
    case 's':
      if((s = (char*)*argp++) == 0)
801004c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801004c7:	8d 50 04             	lea    0x4(%eax),%edx
801004ca:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004cd:	8b 00                	mov    (%eax),%eax
801004cf:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004d2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004d6:	75 09                	jne    801004e1 <cprintf+0x119>
        s = "(null)";
801004d8:	c7 45 ec 9a 84 10 80 	movl   $0x8010849a,-0x14(%ebp)
      for(; *s; s++)
801004df:	eb 17                	jmp    801004f8 <cprintf+0x130>
801004e1:	eb 15                	jmp    801004f8 <cprintf+0x130>
        consputc(*s);
801004e3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004e6:	0f b6 00             	movzbl (%eax),%eax
801004e9:	0f be c0             	movsbl %al,%eax
801004ec:	89 04 24             	mov    %eax,(%esp)
801004ef:	e8 98 02 00 00       	call   8010078c <consputc>
      for(; *s; s++)
801004f4:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004fb:	0f b6 00             	movzbl (%eax),%eax
801004fe:	84 c0                	test   %al,%al
80100500:	75 e1                	jne    801004e3 <cprintf+0x11b>
      break;
80100502:	eb 26                	jmp    8010052a <cprintf+0x162>
    case '%':
      consputc('%');
80100504:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
8010050b:	e8 7c 02 00 00       	call   8010078c <consputc>
      break;
80100510:	eb 18                	jmp    8010052a <cprintf+0x162>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
80100512:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
80100519:	e8 6e 02 00 00       	call   8010078c <consputc>
      consputc(c);
8010051e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100521:	89 04 24             	mov    %eax,(%esp)
80100524:	e8 63 02 00 00       	call   8010078c <consputc>
      break;
80100529:	90                   	nop
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
8010052a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010052e:	8b 55 08             	mov    0x8(%ebp),%edx
80100531:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100534:	01 d0                	add    %edx,%eax
80100536:	0f b6 00             	movzbl (%eax),%eax
80100539:	0f be c0             	movsbl %al,%eax
8010053c:	25 ff 00 00 00       	and    $0xff,%eax
80100541:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80100544:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100548:	0f 85 bf fe ff ff    	jne    8010040d <cprintf+0x45>
    }
  }

  if(locking)
8010054e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80100552:	74 0c                	je     80100560 <cprintf+0x198>
    release(&cons.lock);
80100554:	c7 04 24 a0 b5 10 80 	movl   $0x8010b5a0,(%esp)
8010055b:	e8 e8 4a 00 00       	call   80105048 <release>
}
80100560:	c9                   	leave  
80100561:	c3                   	ret    

80100562 <panic>:

void
panic(char *s)
{
80100562:	55                   	push   %ebp
80100563:	89 e5                	mov    %esp,%ebp
80100565:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];

  cli();
80100568:	e8 a6 fd ff ff       	call   80100313 <cli>
  cons.locking = 0;
8010056d:	c7 05 d4 b5 10 80 00 	movl   $0x0,0x8010b5d4
80100574:	00 00 00 
  // use lapiccpunum so that we can call panic from mycpu()
  cprintf("lapicid %d: panic: ", lapicid());
80100577:	e8 b3 29 00 00       	call   80102f2f <lapicid>
8010057c:	89 44 24 04          	mov    %eax,0x4(%esp)
80100580:	c7 04 24 a1 84 10 80 	movl   $0x801084a1,(%esp)
80100587:	e8 3c fe ff ff       	call   801003c8 <cprintf>
  cprintf(s);
8010058c:	8b 45 08             	mov    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 31 fe ff ff       	call   801003c8 <cprintf>
  cprintf("\n");
80100597:	c7 04 24 b5 84 10 80 	movl   $0x801084b5,(%esp)
8010059e:	e8 25 fe ff ff       	call   801003c8 <cprintf>
  getcallerpcs(&s, pcs);
801005a3:	8d 45 cc             	lea    -0x34(%ebp),%eax
801005a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801005aa:	8d 45 08             	lea    0x8(%ebp),%eax
801005ad:	89 04 24             	mov    %eax,(%esp)
801005b0:	e8 de 4a 00 00       	call   80105093 <getcallerpcs>
  for(i=0; i<10; i++)
801005b5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801005bc:	eb 1b                	jmp    801005d9 <panic+0x77>
    cprintf(" %p", pcs[i]);
801005be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005c1:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801005c9:	c7 04 24 b7 84 10 80 	movl   $0x801084b7,(%esp)
801005d0:	e8 f3 fd ff ff       	call   801003c8 <cprintf>
  for(i=0; i<10; i++)
801005d5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005d9:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005dd:	7e df                	jle    801005be <panic+0x5c>
  panicked = 1; // freeze other CPU
801005df:	c7 05 80 b5 10 80 01 	movl   $0x1,0x8010b580
801005e6:	00 00 00 
  for(;;)
    ;
801005e9:	eb fe                	jmp    801005e9 <panic+0x87>

801005eb <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005eb:	55                   	push   %ebp
801005ec:	89 e5                	mov    %esp,%ebp
801005ee:	83 ec 28             	sub    $0x28,%esp
  int pos;

  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005f1:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005f8:	00 
801005f9:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100600:	e8 f0 fc ff ff       	call   801002f5 <outb>
  pos = inb(CRTPORT+1) << 8;
80100605:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010060c:	e8 c7 fc ff ff       	call   801002d8 <inb>
80100611:	0f b6 c0             	movzbl %al,%eax
80100614:	c1 e0 08             	shl    $0x8,%eax
80100617:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
8010061a:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100621:	00 
80100622:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100629:	e8 c7 fc ff ff       	call   801002f5 <outb>
  pos |= inb(CRTPORT+1);
8010062e:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100635:	e8 9e fc ff ff       	call   801002d8 <inb>
8010063a:	0f b6 c0             	movzbl %al,%eax
8010063d:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
80100640:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100644:	75 30                	jne    80100676 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100646:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80100649:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010064e:	89 c8                	mov    %ecx,%eax
80100650:	f7 ea                	imul   %edx
80100652:	c1 fa 05             	sar    $0x5,%edx
80100655:	89 c8                	mov    %ecx,%eax
80100657:	c1 f8 1f             	sar    $0x1f,%eax
8010065a:	29 c2                	sub    %eax,%edx
8010065c:	89 d0                	mov    %edx,%eax
8010065e:	c1 e0 02             	shl    $0x2,%eax
80100661:	01 d0                	add    %edx,%eax
80100663:	c1 e0 04             	shl    $0x4,%eax
80100666:	29 c1                	sub    %eax,%ecx
80100668:	89 ca                	mov    %ecx,%edx
8010066a:	b8 50 00 00 00       	mov    $0x50,%eax
8010066f:	29 d0                	sub    %edx,%eax
80100671:	01 45 f4             	add    %eax,-0xc(%ebp)
80100674:	eb 35                	jmp    801006ab <cgaputc+0xc0>
  else if(c == BACKSPACE){
80100676:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010067d:	75 0c                	jne    8010068b <cgaputc+0xa0>
    if(pos > 0) --pos;
8010067f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100683:	7e 26                	jle    801006ab <cgaputc+0xc0>
80100685:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100689:	eb 20                	jmp    801006ab <cgaputc+0xc0>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010068b:	8b 0d 00 90 10 80    	mov    0x80109000,%ecx
80100691:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100694:	8d 50 01             	lea    0x1(%eax),%edx
80100697:	89 55 f4             	mov    %edx,-0xc(%ebp)
8010069a:	01 c0                	add    %eax,%eax
8010069c:	8d 14 01             	lea    (%ecx,%eax,1),%edx
8010069f:	8b 45 08             	mov    0x8(%ebp),%eax
801006a2:	0f b6 c0             	movzbl %al,%eax
801006a5:	80 cc 07             	or     $0x7,%ah
801006a8:	66 89 02             	mov    %ax,(%edx)

  if(pos < 0 || pos > 25*80)
801006ab:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801006af:	78 09                	js     801006ba <cgaputc+0xcf>
801006b1:	81 7d f4 d0 07 00 00 	cmpl   $0x7d0,-0xc(%ebp)
801006b8:	7e 0c                	jle    801006c6 <cgaputc+0xdb>
    panic("pos under/overflow");
801006ba:	c7 04 24 bb 84 10 80 	movl   $0x801084bb,(%esp)
801006c1:	e8 9c fe ff ff       	call   80100562 <panic>

  if((pos/80) >= 24){  // Scroll up.
801006c6:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
801006cd:	7e 53                	jle    80100722 <cgaputc+0x137>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801006cf:	a1 00 90 10 80       	mov    0x80109000,%eax
801006d4:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
801006da:	a1 00 90 10 80       	mov    0x80109000,%eax
801006df:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006e6:	00 
801006e7:	89 54 24 04          	mov    %edx,0x4(%esp)
801006eb:	89 04 24             	mov    %eax,(%esp)
801006ee:	e8 2e 4c 00 00       	call   80105321 <memmove>
    pos -= 80;
801006f3:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006f7:	b8 80 07 00 00       	mov    $0x780,%eax
801006fc:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006ff:	8d 14 00             	lea    (%eax,%eax,1),%edx
80100702:	a1 00 90 10 80       	mov    0x80109000,%eax
80100707:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010070a:	01 c9                	add    %ecx,%ecx
8010070c:	01 c8                	add    %ecx,%eax
8010070e:	89 54 24 08          	mov    %edx,0x8(%esp)
80100712:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100719:	00 
8010071a:	89 04 24             	mov    %eax,(%esp)
8010071d:	e8 30 4b 00 00       	call   80105252 <memset>
  }

  outb(CRTPORT, 14);
80100722:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
80100729:	00 
8010072a:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100731:	e8 bf fb ff ff       	call   801002f5 <outb>
  outb(CRTPORT+1, pos>>8);
80100736:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100739:	c1 f8 08             	sar    $0x8,%eax
8010073c:	0f b6 c0             	movzbl %al,%eax
8010073f:	89 44 24 04          	mov    %eax,0x4(%esp)
80100743:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010074a:	e8 a6 fb ff ff       	call   801002f5 <outb>
  outb(CRTPORT, 15);
8010074f:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100756:	00 
80100757:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
8010075e:	e8 92 fb ff ff       	call   801002f5 <outb>
  outb(CRTPORT+1, pos);
80100763:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100766:	0f b6 c0             	movzbl %al,%eax
80100769:	89 44 24 04          	mov    %eax,0x4(%esp)
8010076d:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100774:	e8 7c fb ff ff       	call   801002f5 <outb>
  crt[pos] = ' ' | 0x0700;
80100779:	a1 00 90 10 80       	mov    0x80109000,%eax
8010077e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100781:	01 d2                	add    %edx,%edx
80100783:	01 d0                	add    %edx,%eax
80100785:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
8010078a:	c9                   	leave  
8010078b:	c3                   	ret    

8010078c <consputc>:

void
consputc(int c)
{
8010078c:	55                   	push   %ebp
8010078d:	89 e5                	mov    %esp,%ebp
8010078f:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100792:	a1 80 b5 10 80       	mov    0x8010b580,%eax
80100797:	85 c0                	test   %eax,%eax
80100799:	74 07                	je     801007a2 <consputc+0x16>
    cli();
8010079b:	e8 73 fb ff ff       	call   80100313 <cli>
    for(;;)
      ;
801007a0:	eb fe                	jmp    801007a0 <consputc+0x14>
  }

  if(c == BACKSPACE){
801007a2:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
801007a9:	75 26                	jne    801007d1 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
801007ab:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801007b2:	e8 fa 63 00 00       	call   80106bb1 <uartputc>
801007b7:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801007be:	e8 ee 63 00 00       	call   80106bb1 <uartputc>
801007c3:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801007ca:	e8 e2 63 00 00       	call   80106bb1 <uartputc>
801007cf:	eb 0b                	jmp    801007dc <consputc+0x50>
  } else
    uartputc(c);
801007d1:	8b 45 08             	mov    0x8(%ebp),%eax
801007d4:	89 04 24             	mov    %eax,(%esp)
801007d7:	e8 d5 63 00 00       	call   80106bb1 <uartputc>
  cgaputc(c);
801007dc:	8b 45 08             	mov    0x8(%ebp),%eax
801007df:	89 04 24             	mov    %eax,(%esp)
801007e2:	e8 04 fe ff ff       	call   801005eb <cgaputc>
}
801007e7:	c9                   	leave  
801007e8:	c3                   	ret    

801007e9 <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007e9:	55                   	push   %ebp
801007ea:	89 e5                	mov    %esp,%ebp
801007ec:	83 ec 28             	sub    $0x28,%esp
  int c, doprocdump = 0;
801007ef:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&cons.lock);
801007f6:	c7 04 24 a0 b5 10 80 	movl   $0x8010b5a0,(%esp)
801007fd:	e8 de 47 00 00       	call   80104fe0 <acquire>
  while((c = getc()) >= 0){
80100802:	e9 39 01 00 00       	jmp    80100940 <consoleintr+0x157>
    switch(c){
80100807:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010080a:	83 f8 10             	cmp    $0x10,%eax
8010080d:	74 1e                	je     8010082d <consoleintr+0x44>
8010080f:	83 f8 10             	cmp    $0x10,%eax
80100812:	7f 0a                	jg     8010081e <consoleintr+0x35>
80100814:	83 f8 08             	cmp    $0x8,%eax
80100817:	74 66                	je     8010087f <consoleintr+0x96>
80100819:	e9 93 00 00 00       	jmp    801008b1 <consoleintr+0xc8>
8010081e:	83 f8 15             	cmp    $0x15,%eax
80100821:	74 31                	je     80100854 <consoleintr+0x6b>
80100823:	83 f8 7f             	cmp    $0x7f,%eax
80100826:	74 57                	je     8010087f <consoleintr+0x96>
80100828:	e9 84 00 00 00       	jmp    801008b1 <consoleintr+0xc8>
    case C('P'):  // Process listing.
      // procdump() locks cons.lock indirectly; invoke later
      doprocdump = 1;
8010082d:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
      break;
80100834:	e9 07 01 00 00       	jmp    80100940 <consoleintr+0x157>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
80100839:	a1 28 10 11 80       	mov    0x80111028,%eax
8010083e:	83 e8 01             	sub    $0x1,%eax
80100841:	a3 28 10 11 80       	mov    %eax,0x80111028
        consputc(BACKSPACE);
80100846:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
8010084d:	e8 3a ff ff ff       	call   8010078c <consputc>
80100852:	eb 01                	jmp    80100855 <consoleintr+0x6c>
      while(input.e != input.w &&
80100854:	90                   	nop
80100855:	8b 15 28 10 11 80    	mov    0x80111028,%edx
8010085b:	a1 24 10 11 80       	mov    0x80111024,%eax
80100860:	39 c2                	cmp    %eax,%edx
80100862:	74 16                	je     8010087a <consoleintr+0x91>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100864:	a1 28 10 11 80       	mov    0x80111028,%eax
80100869:	83 e8 01             	sub    $0x1,%eax
8010086c:	83 e0 7f             	and    $0x7f,%eax
8010086f:	0f b6 80 a0 0f 11 80 	movzbl -0x7feef060(%eax),%eax
      while(input.e != input.w &&
80100876:	3c 0a                	cmp    $0xa,%al
80100878:	75 bf                	jne    80100839 <consoleintr+0x50>
      }
      break;
8010087a:	e9 c1 00 00 00       	jmp    80100940 <consoleintr+0x157>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
8010087f:	8b 15 28 10 11 80    	mov    0x80111028,%edx
80100885:	a1 24 10 11 80       	mov    0x80111024,%eax
8010088a:	39 c2                	cmp    %eax,%edx
8010088c:	74 1e                	je     801008ac <consoleintr+0xc3>
        input.e--;
8010088e:	a1 28 10 11 80       	mov    0x80111028,%eax
80100893:	83 e8 01             	sub    $0x1,%eax
80100896:	a3 28 10 11 80       	mov    %eax,0x80111028
        consputc(BACKSPACE);
8010089b:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
801008a2:	e8 e5 fe ff ff       	call   8010078c <consputc>
      }
      break;
801008a7:	e9 94 00 00 00       	jmp    80100940 <consoleintr+0x157>
801008ac:	e9 8f 00 00 00       	jmp    80100940 <consoleintr+0x157>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
801008b1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801008b5:	0f 84 84 00 00 00    	je     8010093f <consoleintr+0x156>
801008bb:	8b 15 28 10 11 80    	mov    0x80111028,%edx
801008c1:	a1 20 10 11 80       	mov    0x80111020,%eax
801008c6:	29 c2                	sub    %eax,%edx
801008c8:	89 d0                	mov    %edx,%eax
801008ca:	83 f8 7f             	cmp    $0x7f,%eax
801008cd:	77 70                	ja     8010093f <consoleintr+0x156>
        c = (c == '\r') ? '\n' : c;
801008cf:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801008d3:	74 05                	je     801008da <consoleintr+0xf1>
801008d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801008d8:	eb 05                	jmp    801008df <consoleintr+0xf6>
801008da:	b8 0a 00 00 00       	mov    $0xa,%eax
801008df:	89 45 f0             	mov    %eax,-0x10(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
801008e2:	a1 28 10 11 80       	mov    0x80111028,%eax
801008e7:	8d 50 01             	lea    0x1(%eax),%edx
801008ea:	89 15 28 10 11 80    	mov    %edx,0x80111028
801008f0:	83 e0 7f             	and    $0x7f,%eax
801008f3:	89 c2                	mov    %eax,%edx
801008f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801008f8:	88 82 a0 0f 11 80    	mov    %al,-0x7feef060(%edx)
        consputc(c);
801008fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100901:	89 04 24             	mov    %eax,(%esp)
80100904:	e8 83 fe ff ff       	call   8010078c <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
80100909:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
8010090d:	74 18                	je     80100927 <consoleintr+0x13e>
8010090f:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
80100913:	74 12                	je     80100927 <consoleintr+0x13e>
80100915:	a1 28 10 11 80       	mov    0x80111028,%eax
8010091a:	8b 15 20 10 11 80    	mov    0x80111020,%edx
80100920:	83 ea 80             	sub    $0xffffff80,%edx
80100923:	39 d0                	cmp    %edx,%eax
80100925:	75 18                	jne    8010093f <consoleintr+0x156>
          input.w = input.e;
80100927:	a1 28 10 11 80       	mov    0x80111028,%eax
8010092c:	a3 24 10 11 80       	mov    %eax,0x80111024
          wakeup(&input.r);
80100931:	c7 04 24 20 10 11 80 	movl   $0x80111020,(%esp)
80100938:	e8 93 41 00 00       	call   80104ad0 <wakeup>
        }
      }
      break;
8010093d:	eb 00                	jmp    8010093f <consoleintr+0x156>
8010093f:	90                   	nop
  while((c = getc()) >= 0){
80100940:	8b 45 08             	mov    0x8(%ebp),%eax
80100943:	ff d0                	call   *%eax
80100945:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100948:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010094c:	0f 89 b5 fe ff ff    	jns    80100807 <consoleintr+0x1e>
    }
  }
  release(&cons.lock);
80100952:	c7 04 24 a0 b5 10 80 	movl   $0x8010b5a0,(%esp)
80100959:	e8 ea 46 00 00       	call   80105048 <release>
  if(doprocdump) {
8010095e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100962:	74 05                	je     80100969 <consoleintr+0x180>
    procdump();  // now call procdump() wo. cons.lock held
80100964:	e8 0d 42 00 00       	call   80104b76 <procdump>
  }
}
80100969:	c9                   	leave  
8010096a:	c3                   	ret    

8010096b <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
8010096b:	55                   	push   %ebp
8010096c:	89 e5                	mov    %esp,%ebp
8010096e:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
80100971:	8b 45 08             	mov    0x8(%ebp),%eax
80100974:	89 04 24             	mov    %eax,(%esp)
80100977:	e8 ee 10 00 00       	call   80101a6a <iunlock>
  target = n;
8010097c:	8b 45 10             	mov    0x10(%ebp),%eax
8010097f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&cons.lock);
80100982:	c7 04 24 a0 b5 10 80 	movl   $0x8010b5a0,(%esp)
80100989:	e8 52 46 00 00       	call   80104fe0 <acquire>
  while(n > 0){
8010098e:	e9 a9 00 00 00       	jmp    80100a3c <consoleread+0xd1>
    while(input.r == input.w){
80100993:	eb 41                	jmp    801009d6 <consoleread+0x6b>
      if(myproc()->killed){
80100995:	e8 c7 37 00 00       	call   80104161 <myproc>
8010099a:	8b 40 24             	mov    0x24(%eax),%eax
8010099d:	85 c0                	test   %eax,%eax
8010099f:	74 21                	je     801009c2 <consoleread+0x57>
        release(&cons.lock);
801009a1:	c7 04 24 a0 b5 10 80 	movl   $0x8010b5a0,(%esp)
801009a8:	e8 9b 46 00 00       	call   80105048 <release>
        ilock(ip);
801009ad:	8b 45 08             	mov    0x8(%ebp),%eax
801009b0:	89 04 24             	mov    %eax,(%esp)
801009b3:	e8 a5 0f 00 00       	call   8010195d <ilock>
        return -1;
801009b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801009bd:	e9 a5 00 00 00       	jmp    80100a67 <consoleread+0xfc>
      }
      sleep(&input.r, &cons.lock);
801009c2:	c7 44 24 04 a0 b5 10 	movl   $0x8010b5a0,0x4(%esp)
801009c9:	80 
801009ca:	c7 04 24 20 10 11 80 	movl   $0x80111020,(%esp)
801009d1:	e8 23 40 00 00       	call   801049f9 <sleep>
    while(input.r == input.w){
801009d6:	8b 15 20 10 11 80    	mov    0x80111020,%edx
801009dc:	a1 24 10 11 80       	mov    0x80111024,%eax
801009e1:	39 c2                	cmp    %eax,%edx
801009e3:	74 b0                	je     80100995 <consoleread+0x2a>
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009e5:	a1 20 10 11 80       	mov    0x80111020,%eax
801009ea:	8d 50 01             	lea    0x1(%eax),%edx
801009ed:	89 15 20 10 11 80    	mov    %edx,0x80111020
801009f3:	83 e0 7f             	and    $0x7f,%eax
801009f6:	0f b6 80 a0 0f 11 80 	movzbl -0x7feef060(%eax),%eax
801009fd:	0f be c0             	movsbl %al,%eax
80100a00:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(c == C('D')){  // EOF
80100a03:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
80100a07:	75 19                	jne    80100a22 <consoleread+0xb7>
      if(n < target){
80100a09:	8b 45 10             	mov    0x10(%ebp),%eax
80100a0c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80100a0f:	73 0f                	jae    80100a20 <consoleread+0xb5>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
80100a11:	a1 20 10 11 80       	mov    0x80111020,%eax
80100a16:	83 e8 01             	sub    $0x1,%eax
80100a19:	a3 20 10 11 80       	mov    %eax,0x80111020
      }
      break;
80100a1e:	eb 26                	jmp    80100a46 <consoleread+0xdb>
80100a20:	eb 24                	jmp    80100a46 <consoleread+0xdb>
    }
    *dst++ = c;
80100a22:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a25:	8d 50 01             	lea    0x1(%eax),%edx
80100a28:	89 55 0c             	mov    %edx,0xc(%ebp)
80100a2b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80100a2e:	88 10                	mov    %dl,(%eax)
    --n;
80100a30:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
80100a34:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100a38:	75 02                	jne    80100a3c <consoleread+0xd1>
      break;
80100a3a:	eb 0a                	jmp    80100a46 <consoleread+0xdb>
  while(n > 0){
80100a3c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100a40:	0f 8f 4d ff ff ff    	jg     80100993 <consoleread+0x28>
  }
  release(&cons.lock);
80100a46:	c7 04 24 a0 b5 10 80 	movl   $0x8010b5a0,(%esp)
80100a4d:	e8 f6 45 00 00       	call   80105048 <release>
  ilock(ip);
80100a52:	8b 45 08             	mov    0x8(%ebp),%eax
80100a55:	89 04 24             	mov    %eax,(%esp)
80100a58:	e8 00 0f 00 00       	call   8010195d <ilock>

  return target - n;
80100a5d:	8b 45 10             	mov    0x10(%ebp),%eax
80100a60:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a63:	29 c2                	sub    %eax,%edx
80100a65:	89 d0                	mov    %edx,%eax
}
80100a67:	c9                   	leave  
80100a68:	c3                   	ret    

80100a69 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a69:	55                   	push   %ebp
80100a6a:	89 e5                	mov    %esp,%ebp
80100a6c:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a6f:	8b 45 08             	mov    0x8(%ebp),%eax
80100a72:	89 04 24             	mov    %eax,(%esp)
80100a75:	e8 f0 0f 00 00       	call   80101a6a <iunlock>
  acquire(&cons.lock);
80100a7a:	c7 04 24 a0 b5 10 80 	movl   $0x8010b5a0,(%esp)
80100a81:	e8 5a 45 00 00       	call   80104fe0 <acquire>
  for(i = 0; i < n; i++)
80100a86:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a8d:	eb 1d                	jmp    80100aac <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a8f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a92:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a95:	01 d0                	add    %edx,%eax
80100a97:	0f b6 00             	movzbl (%eax),%eax
80100a9a:	0f be c0             	movsbl %al,%eax
80100a9d:	0f b6 c0             	movzbl %al,%eax
80100aa0:	89 04 24             	mov    %eax,(%esp)
80100aa3:	e8 e4 fc ff ff       	call   8010078c <consputc>
  for(i = 0; i < n; i++)
80100aa8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100aac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100aaf:	3b 45 10             	cmp    0x10(%ebp),%eax
80100ab2:	7c db                	jl     80100a8f <consolewrite+0x26>
  release(&cons.lock);
80100ab4:	c7 04 24 a0 b5 10 80 	movl   $0x8010b5a0,(%esp)
80100abb:	e8 88 45 00 00       	call   80105048 <release>
  ilock(ip);
80100ac0:	8b 45 08             	mov    0x8(%ebp),%eax
80100ac3:	89 04 24             	mov    %eax,(%esp)
80100ac6:	e8 92 0e 00 00       	call   8010195d <ilock>

  return n;
80100acb:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100ace:	c9                   	leave  
80100acf:	c3                   	ret    

80100ad0 <consoleinit>:

void
consoleinit(void)
{
80100ad0:	55                   	push   %ebp
80100ad1:	89 e5                	mov    %esp,%ebp
80100ad3:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100ad6:	c7 44 24 04 ce 84 10 	movl   $0x801084ce,0x4(%esp)
80100add:	80 
80100ade:	c7 04 24 a0 b5 10 80 	movl   $0x8010b5a0,(%esp)
80100ae5:	e8 d5 44 00 00       	call   80104fbf <initlock>

  devsw[CONSOLE].write = consolewrite;
80100aea:	c7 05 ec 19 11 80 69 	movl   $0x80100a69,0x801119ec
80100af1:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100af4:	c7 05 e8 19 11 80 6b 	movl   $0x8010096b,0x801119e8
80100afb:	09 10 80 
  cons.locking = 1;
80100afe:	c7 05 d4 b5 10 80 01 	movl   $0x1,0x8010b5d4
80100b05:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
80100b08:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100b0f:	00 
80100b10:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100b17:	e8 23 1f 00 00       	call   80102a3f <ioapicenable>
}
80100b1c:	c9                   	leave  
80100b1d:	c3                   	ret    

80100b1e <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100b1e:	55                   	push   %ebp
80100b1f:	89 e5                	mov    %esp,%ebp
80100b21:	81 ec 38 01 00 00    	sub    $0x138,%esp
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  struct proc *curproc = myproc();
80100b27:	e8 35 36 00 00       	call   80104161 <myproc>
80100b2c:	89 45 d0             	mov    %eax,-0x30(%ebp)

  begin_op();
80100b2f:	e8 53 29 00 00       	call   80103487 <begin_op>

  if((ip = namei(path)) == 0){
80100b34:	8b 45 08             	mov    0x8(%ebp),%eax
80100b37:	89 04 24             	mov    %eax,(%esp)
80100b3a:	e8 58 19 00 00       	call   80102497 <namei>
80100b3f:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b42:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b46:	75 1b                	jne    80100b63 <exec+0x45>
    end_op();
80100b48:	e8 be 29 00 00       	call   8010350b <end_op>
    cprintf("exec: fail\n");
80100b4d:	c7 04 24 d6 84 10 80 	movl   $0x801084d6,(%esp)
80100b54:	e8 6f f8 ff ff       	call   801003c8 <cprintf>
    return -1;
80100b59:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b5e:	e9 04 04 00 00       	jmp    80100f67 <exec+0x449>
  }
  ilock(ip);
80100b63:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b66:	89 04 24             	mov    %eax,(%esp)
80100b69:	e8 ef 0d 00 00       	call   8010195d <ilock>
  pgdir = 0;
80100b6e:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
80100b75:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b7c:	00 
80100b7d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b84:	00 
80100b85:	8d 85 08 ff ff ff    	lea    -0xf8(%ebp),%eax
80100b8b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b8f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b92:	89 04 24             	mov    %eax,(%esp)
80100b95:	e8 60 12 00 00       	call   80101dfa <readi>
80100b9a:	83 f8 34             	cmp    $0x34,%eax
80100b9d:	74 05                	je     80100ba4 <exec+0x86>
    goto bad;
80100b9f:	e9 97 03 00 00       	jmp    80100f3b <exec+0x41d>
  if(elf.magic != ELF_MAGIC)
80100ba4:	8b 85 08 ff ff ff    	mov    -0xf8(%ebp),%eax
80100baa:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100baf:	74 05                	je     80100bb6 <exec+0x98>
    goto bad;
80100bb1:	e9 85 03 00 00       	jmp    80100f3b <exec+0x41d>

  if((pgdir = setupkvm()) == 0)
80100bb6:	e8 f3 6f 00 00       	call   80107bae <setupkvm>
80100bbb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100bbe:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100bc2:	75 05                	jne    80100bc9 <exec+0xab>
    goto bad;
80100bc4:	e9 72 03 00 00       	jmp    80100f3b <exec+0x41d>

  // Load program into memory.
  sz = 0;
80100bc9:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100bd0:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100bd7:	8b 85 24 ff ff ff    	mov    -0xdc(%ebp),%eax
80100bdd:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100be0:	e9 fc 00 00 00       	jmp    80100ce1 <exec+0x1c3>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100be5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100be8:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100bef:	00 
80100bf0:	89 44 24 08          	mov    %eax,0x8(%esp)
80100bf4:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
80100bfa:	89 44 24 04          	mov    %eax,0x4(%esp)
80100bfe:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c01:	89 04 24             	mov    %eax,(%esp)
80100c04:	e8 f1 11 00 00       	call   80101dfa <readi>
80100c09:	83 f8 20             	cmp    $0x20,%eax
80100c0c:	74 05                	je     80100c13 <exec+0xf5>
      goto bad;
80100c0e:	e9 28 03 00 00       	jmp    80100f3b <exec+0x41d>
    if(ph.type != ELF_PROG_LOAD)
80100c13:	8b 85 e8 fe ff ff    	mov    -0x118(%ebp),%eax
80100c19:	83 f8 01             	cmp    $0x1,%eax
80100c1c:	74 05                	je     80100c23 <exec+0x105>
      continue;
80100c1e:	e9 b1 00 00 00       	jmp    80100cd4 <exec+0x1b6>
    if(ph.memsz < ph.filesz)
80100c23:	8b 95 fc fe ff ff    	mov    -0x104(%ebp),%edx
80100c29:	8b 85 f8 fe ff ff    	mov    -0x108(%ebp),%eax
80100c2f:	39 c2                	cmp    %eax,%edx
80100c31:	73 05                	jae    80100c38 <exec+0x11a>
      goto bad;
80100c33:	e9 03 03 00 00       	jmp    80100f3b <exec+0x41d>
    if(ph.vaddr + ph.memsz < ph.vaddr)
80100c38:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c3e:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100c44:	01 c2                	add    %eax,%edx
80100c46:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100c4c:	39 c2                	cmp    %eax,%edx
80100c4e:	73 05                	jae    80100c55 <exec+0x137>
      goto bad;
80100c50:	e9 e6 02 00 00       	jmp    80100f3b <exec+0x41d>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100c55:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c5b:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100c61:	01 d0                	add    %edx,%eax
80100c63:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c67:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c6a:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c6e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c71:	89 04 24             	mov    %eax,(%esp)
80100c74:	e8 0b 73 00 00       	call   80107f84 <allocuvm>
80100c79:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c7c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c80:	75 05                	jne    80100c87 <exec+0x169>
      goto bad;
80100c82:	e9 b4 02 00 00       	jmp    80100f3b <exec+0x41d>
    if(ph.vaddr % PGSIZE != 0)
80100c87:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100c8d:	25 ff 0f 00 00       	and    $0xfff,%eax
80100c92:	85 c0                	test   %eax,%eax
80100c94:	74 05                	je     80100c9b <exec+0x17d>
      goto bad;
80100c96:	e9 a0 02 00 00       	jmp    80100f3b <exec+0x41d>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c9b:	8b 8d f8 fe ff ff    	mov    -0x108(%ebp),%ecx
80100ca1:	8b 95 ec fe ff ff    	mov    -0x114(%ebp),%edx
80100ca7:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100cad:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100cb1:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100cb5:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100cb8:	89 54 24 08          	mov    %edx,0x8(%esp)
80100cbc:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cc0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cc3:	89 04 24             	mov    %eax,(%esp)
80100cc6:	e8 d6 71 00 00       	call   80107ea1 <loaduvm>
80100ccb:	85 c0                	test   %eax,%eax
80100ccd:	79 05                	jns    80100cd4 <exec+0x1b6>
      goto bad;
80100ccf:	e9 67 02 00 00       	jmp    80100f3b <exec+0x41d>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100cd4:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100cd8:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100cdb:	83 c0 20             	add    $0x20,%eax
80100cde:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100ce1:	0f b7 85 34 ff ff ff 	movzwl -0xcc(%ebp),%eax
80100ce8:	0f b7 c0             	movzwl %ax,%eax
80100ceb:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100cee:	0f 8f f1 fe ff ff    	jg     80100be5 <exec+0xc7>
  }
  iunlockput(ip);
80100cf4:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100cf7:	89 04 24             	mov    %eax,(%esp)
80100cfa:	e8 60 0e 00 00       	call   80101b5f <iunlockput>
  end_op();
80100cff:	e8 07 28 00 00       	call   8010350b <end_op>
  ip = 0;
80100d04:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100d0b:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d0e:	05 ff 0f 00 00       	add    $0xfff,%eax
80100d13:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100d18:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100d1b:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d1e:	05 00 20 00 00       	add    $0x2000,%eax
80100d23:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d27:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d2e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d31:	89 04 24             	mov    %eax,(%esp)
80100d34:	e8 4b 72 00 00       	call   80107f84 <allocuvm>
80100d39:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d3c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100d40:	75 05                	jne    80100d47 <exec+0x229>
    goto bad;
80100d42:	e9 f4 01 00 00       	jmp    80100f3b <exec+0x41d>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100d47:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d4a:	2d 00 20 00 00       	sub    $0x2000,%eax
80100d4f:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d53:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d56:	89 04 24             	mov    %eax,(%esp)
80100d59:	e8 99 74 00 00       	call   801081f7 <clearpteu>
  sp = sz;
80100d5e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d61:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d64:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100d6b:	e9 9a 00 00 00       	jmp    80100e0a <exec+0x2ec>
    if(argc >= MAXARG)
80100d70:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100d74:	76 05                	jbe    80100d7b <exec+0x25d>
      goto bad;
80100d76:	e9 c0 01 00 00       	jmp    80100f3b <exec+0x41d>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d7b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d7e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d85:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d88:	01 d0                	add    %edx,%eax
80100d8a:	8b 00                	mov    (%eax),%eax
80100d8c:	89 04 24             	mov    %eax,(%esp)
80100d8f:	e8 28 47 00 00       	call   801054bc <strlen>
80100d94:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100d97:	29 c2                	sub    %eax,%edx
80100d99:	89 d0                	mov    %edx,%eax
80100d9b:	83 e8 01             	sub    $0x1,%eax
80100d9e:	83 e0 fc             	and    $0xfffffffc,%eax
80100da1:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100da4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100da7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100dae:	8b 45 0c             	mov    0xc(%ebp),%eax
80100db1:	01 d0                	add    %edx,%eax
80100db3:	8b 00                	mov    (%eax),%eax
80100db5:	89 04 24             	mov    %eax,(%esp)
80100db8:	e8 ff 46 00 00       	call   801054bc <strlen>
80100dbd:	83 c0 01             	add    $0x1,%eax
80100dc0:	89 c2                	mov    %eax,%edx
80100dc2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dc5:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100dcc:	8b 45 0c             	mov    0xc(%ebp),%eax
80100dcf:	01 c8                	add    %ecx,%eax
80100dd1:	8b 00                	mov    (%eax),%eax
80100dd3:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100dd7:	89 44 24 08          	mov    %eax,0x8(%esp)
80100ddb:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100dde:	89 44 24 04          	mov    %eax,0x4(%esp)
80100de2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100de5:	89 04 24             	mov    %eax,(%esp)
80100de8:	e8 cd 75 00 00       	call   801083ba <copyout>
80100ded:	85 c0                	test   %eax,%eax
80100def:	79 05                	jns    80100df6 <exec+0x2d8>
      goto bad;
80100df1:	e9 45 01 00 00       	jmp    80100f3b <exec+0x41d>
    ustack[3+argc] = sp;
80100df6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100df9:	8d 50 03             	lea    0x3(%eax),%edx
80100dfc:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100dff:	89 84 95 3c ff ff ff 	mov    %eax,-0xc4(%ebp,%edx,4)
  for(argc = 0; argv[argc]; argc++) {
80100e06:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100e0a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e0d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e14:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e17:	01 d0                	add    %edx,%eax
80100e19:	8b 00                	mov    (%eax),%eax
80100e1b:	85 c0                	test   %eax,%eax
80100e1d:	0f 85 4d ff ff ff    	jne    80100d70 <exec+0x252>
  }
  ustack[3+argc] = 0;
80100e23:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e26:	83 c0 03             	add    $0x3,%eax
80100e29:	c7 84 85 3c ff ff ff 	movl   $0x0,-0xc4(%ebp,%eax,4)
80100e30:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100e34:	c7 85 3c ff ff ff ff 	movl   $0xffffffff,-0xc4(%ebp)
80100e3b:	ff ff ff 
  ustack[1] = argc;
80100e3e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e41:	89 85 40 ff ff ff    	mov    %eax,-0xc0(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100e47:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e4a:	83 c0 01             	add    $0x1,%eax
80100e4d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e54:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e57:	29 d0                	sub    %edx,%eax
80100e59:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)

  sp -= (3+argc+1) * 4;
80100e5f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e62:	83 c0 04             	add    $0x4,%eax
80100e65:	c1 e0 02             	shl    $0x2,%eax
80100e68:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100e6b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e6e:	83 c0 04             	add    $0x4,%eax
80100e71:	c1 e0 02             	shl    $0x2,%eax
80100e74:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100e78:	8d 85 3c ff ff ff    	lea    -0xc4(%ebp),%eax
80100e7e:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e82:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e85:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e89:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e8c:	89 04 24             	mov    %eax,(%esp)
80100e8f:	e8 26 75 00 00       	call   801083ba <copyout>
80100e94:	85 c0                	test   %eax,%eax
80100e96:	79 05                	jns    80100e9d <exec+0x37f>
    goto bad;
80100e98:	e9 9e 00 00 00       	jmp    80100f3b <exec+0x41d>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e9d:	8b 45 08             	mov    0x8(%ebp),%eax
80100ea0:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100ea3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ea6:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100ea9:	eb 17                	jmp    80100ec2 <exec+0x3a4>
    if(*s == '/')
80100eab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100eae:	0f b6 00             	movzbl (%eax),%eax
80100eb1:	3c 2f                	cmp    $0x2f,%al
80100eb3:	75 09                	jne    80100ebe <exec+0x3a0>
      last = s+1;
80100eb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100eb8:	83 c0 01             	add    $0x1,%eax
80100ebb:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(last=s=path; *s; s++)
80100ebe:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100ec2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ec5:	0f b6 00             	movzbl (%eax),%eax
80100ec8:	84 c0                	test   %al,%al
80100eca:	75 df                	jne    80100eab <exec+0x38d>
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100ecc:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ecf:	8d 50 6c             	lea    0x6c(%eax),%edx
80100ed2:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100ed9:	00 
80100eda:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100edd:	89 44 24 04          	mov    %eax,0x4(%esp)
80100ee1:	89 14 24             	mov    %edx,(%esp)
80100ee4:	e8 89 45 00 00       	call   80105472 <safestrcpy>

  // Commit to the user image.
  oldpgdir = curproc->pgdir;
80100ee9:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100eec:	8b 40 04             	mov    0x4(%eax),%eax
80100eef:	89 45 cc             	mov    %eax,-0x34(%ebp)
  curproc->pgdir = pgdir;
80100ef2:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ef5:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100ef8:	89 50 04             	mov    %edx,0x4(%eax)
  curproc->sz = sz;
80100efb:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100efe:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100f01:	89 10                	mov    %edx,(%eax)
  curproc->tf->eip = elf.entry;  // main
80100f03:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f06:	8b 40 18             	mov    0x18(%eax),%eax
80100f09:	8b 95 20 ff ff ff    	mov    -0xe0(%ebp),%edx
80100f0f:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100f12:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f15:	8b 40 18             	mov    0x18(%eax),%eax
80100f18:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100f1b:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(curproc);
80100f1e:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f21:	89 04 24             	mov    %eax,(%esp)
80100f24:	e8 5f 6d 00 00       	call   80107c88 <switchuvm>
  freevm(oldpgdir);
80100f29:	8b 45 cc             	mov    -0x34(%ebp),%eax
80100f2c:	89 04 24             	mov    %eax,(%esp)
80100f2f:	e8 2c 72 00 00       	call   80108160 <freevm>
  return 0;
80100f34:	b8 00 00 00 00       	mov    $0x0,%eax
80100f39:	eb 2c                	jmp    80100f67 <exec+0x449>

 bad:
  if(pgdir)
80100f3b:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100f3f:	74 0b                	je     80100f4c <exec+0x42e>
    freevm(pgdir);
80100f41:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100f44:	89 04 24             	mov    %eax,(%esp)
80100f47:	e8 14 72 00 00       	call   80108160 <freevm>
  if(ip){
80100f4c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100f50:	74 10                	je     80100f62 <exec+0x444>
    iunlockput(ip);
80100f52:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100f55:	89 04 24             	mov    %eax,(%esp)
80100f58:	e8 02 0c 00 00       	call   80101b5f <iunlockput>
    end_op();
80100f5d:	e8 a9 25 00 00       	call   8010350b <end_op>
  }
  return -1;
80100f62:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100f67:	c9                   	leave  
80100f68:	c3                   	ret    

80100f69 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100f69:	55                   	push   %ebp
80100f6a:	89 e5                	mov    %esp,%ebp
80100f6c:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100f6f:	c7 44 24 04 e2 84 10 	movl   $0x801084e2,0x4(%esp)
80100f76:	80 
80100f77:	c7 04 24 40 10 11 80 	movl   $0x80111040,(%esp)
80100f7e:	e8 3c 40 00 00       	call   80104fbf <initlock>
}
80100f83:	c9                   	leave  
80100f84:	c3                   	ret    

80100f85 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100f85:	55                   	push   %ebp
80100f86:	89 e5                	mov    %esp,%ebp
80100f88:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100f8b:	c7 04 24 40 10 11 80 	movl   $0x80111040,(%esp)
80100f92:	e8 49 40 00 00       	call   80104fe0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f97:	c7 45 f4 74 10 11 80 	movl   $0x80111074,-0xc(%ebp)
80100f9e:	eb 29                	jmp    80100fc9 <filealloc+0x44>
    if(f->ref == 0){
80100fa0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100fa3:	8b 40 04             	mov    0x4(%eax),%eax
80100fa6:	85 c0                	test   %eax,%eax
80100fa8:	75 1b                	jne    80100fc5 <filealloc+0x40>
      f->ref = 1;
80100faa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100fad:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80100fb4:	c7 04 24 40 10 11 80 	movl   $0x80111040,(%esp)
80100fbb:	e8 88 40 00 00       	call   80105048 <release>
      return f;
80100fc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100fc3:	eb 1e                	jmp    80100fe3 <filealloc+0x5e>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100fc5:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100fc9:	81 7d f4 d4 19 11 80 	cmpl   $0x801119d4,-0xc(%ebp)
80100fd0:	72 ce                	jb     80100fa0 <filealloc+0x1b>
    }
  }
  release(&ftable.lock);
80100fd2:	c7 04 24 40 10 11 80 	movl   $0x80111040,(%esp)
80100fd9:	e8 6a 40 00 00       	call   80105048 <release>
  return 0;
80100fde:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100fe3:	c9                   	leave  
80100fe4:	c3                   	ret    

80100fe5 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100fe5:	55                   	push   %ebp
80100fe6:	89 e5                	mov    %esp,%ebp
80100fe8:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80100feb:	c7 04 24 40 10 11 80 	movl   $0x80111040,(%esp)
80100ff2:	e8 e9 3f 00 00       	call   80104fe0 <acquire>
  if(f->ref < 1)
80100ff7:	8b 45 08             	mov    0x8(%ebp),%eax
80100ffa:	8b 40 04             	mov    0x4(%eax),%eax
80100ffd:	85 c0                	test   %eax,%eax
80100fff:	7f 0c                	jg     8010100d <filedup+0x28>
    panic("filedup");
80101001:	c7 04 24 e9 84 10 80 	movl   $0x801084e9,(%esp)
80101008:	e8 55 f5 ff ff       	call   80100562 <panic>
  f->ref++;
8010100d:	8b 45 08             	mov    0x8(%ebp),%eax
80101010:	8b 40 04             	mov    0x4(%eax),%eax
80101013:	8d 50 01             	lea    0x1(%eax),%edx
80101016:	8b 45 08             	mov    0x8(%ebp),%eax
80101019:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
8010101c:	c7 04 24 40 10 11 80 	movl   $0x80111040,(%esp)
80101023:	e8 20 40 00 00       	call   80105048 <release>
  return f;
80101028:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010102b:	c9                   	leave  
8010102c:	c3                   	ret    

8010102d <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
8010102d:	55                   	push   %ebp
8010102e:	89 e5                	mov    %esp,%ebp
80101030:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80101033:	c7 04 24 40 10 11 80 	movl   $0x80111040,(%esp)
8010103a:	e8 a1 3f 00 00       	call   80104fe0 <acquire>
  if(f->ref < 1)
8010103f:	8b 45 08             	mov    0x8(%ebp),%eax
80101042:	8b 40 04             	mov    0x4(%eax),%eax
80101045:	85 c0                	test   %eax,%eax
80101047:	7f 0c                	jg     80101055 <fileclose+0x28>
    panic("fileclose");
80101049:	c7 04 24 f1 84 10 80 	movl   $0x801084f1,(%esp)
80101050:	e8 0d f5 ff ff       	call   80100562 <panic>
  if(--f->ref > 0){
80101055:	8b 45 08             	mov    0x8(%ebp),%eax
80101058:	8b 40 04             	mov    0x4(%eax),%eax
8010105b:	8d 50 ff             	lea    -0x1(%eax),%edx
8010105e:	8b 45 08             	mov    0x8(%ebp),%eax
80101061:	89 50 04             	mov    %edx,0x4(%eax)
80101064:	8b 45 08             	mov    0x8(%ebp),%eax
80101067:	8b 40 04             	mov    0x4(%eax),%eax
8010106a:	85 c0                	test   %eax,%eax
8010106c:	7e 11                	jle    8010107f <fileclose+0x52>
    release(&ftable.lock);
8010106e:	c7 04 24 40 10 11 80 	movl   $0x80111040,(%esp)
80101075:	e8 ce 3f 00 00       	call   80105048 <release>
8010107a:	e9 82 00 00 00       	jmp    80101101 <fileclose+0xd4>
    return;
  }
  ff = *f;
8010107f:	8b 45 08             	mov    0x8(%ebp),%eax
80101082:	8b 10                	mov    (%eax),%edx
80101084:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101087:	8b 50 04             	mov    0x4(%eax),%edx
8010108a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010108d:	8b 50 08             	mov    0x8(%eax),%edx
80101090:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101093:	8b 50 0c             	mov    0xc(%eax),%edx
80101096:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101099:	8b 50 10             	mov    0x10(%eax),%edx
8010109c:	89 55 f0             	mov    %edx,-0x10(%ebp)
8010109f:	8b 40 14             	mov    0x14(%eax),%eax
801010a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
801010a5:	8b 45 08             	mov    0x8(%ebp),%eax
801010a8:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
801010af:	8b 45 08             	mov    0x8(%ebp),%eax
801010b2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
801010b8:	c7 04 24 40 10 11 80 	movl   $0x80111040,(%esp)
801010bf:	e8 84 3f 00 00       	call   80105048 <release>

  if(ff.type == FD_PIPE)
801010c4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010c7:	83 f8 01             	cmp    $0x1,%eax
801010ca:	75 18                	jne    801010e4 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
801010cc:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
801010d0:	0f be d0             	movsbl %al,%edx
801010d3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801010d6:	89 54 24 04          	mov    %edx,0x4(%esp)
801010da:	89 04 24             	mov    %eax,(%esp)
801010dd:	e8 46 2d 00 00       	call   80103e28 <pipeclose>
801010e2:	eb 1d                	jmp    80101101 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
801010e4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010e7:	83 f8 02             	cmp    $0x2,%eax
801010ea:	75 15                	jne    80101101 <fileclose+0xd4>
    begin_op();
801010ec:	e8 96 23 00 00       	call   80103487 <begin_op>
    iput(ff.ip);
801010f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010f4:	89 04 24             	mov    %eax,(%esp)
801010f7:	e8 b2 09 00 00       	call   80101aae <iput>
    end_op();
801010fc:	e8 0a 24 00 00       	call   8010350b <end_op>
  }
}
80101101:	c9                   	leave  
80101102:	c3                   	ret    

80101103 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80101103:	55                   	push   %ebp
80101104:	89 e5                	mov    %esp,%ebp
80101106:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
80101109:	8b 45 08             	mov    0x8(%ebp),%eax
8010110c:	8b 00                	mov    (%eax),%eax
8010110e:	83 f8 02             	cmp    $0x2,%eax
80101111:	75 38                	jne    8010114b <filestat+0x48>
    ilock(f->ip);
80101113:	8b 45 08             	mov    0x8(%ebp),%eax
80101116:	8b 40 10             	mov    0x10(%eax),%eax
80101119:	89 04 24             	mov    %eax,(%esp)
8010111c:	e8 3c 08 00 00       	call   8010195d <ilock>
    stati(f->ip, st);
80101121:	8b 45 08             	mov    0x8(%ebp),%eax
80101124:	8b 40 10             	mov    0x10(%eax),%eax
80101127:	8b 55 0c             	mov    0xc(%ebp),%edx
8010112a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010112e:	89 04 24             	mov    %eax,(%esp)
80101131:	e8 7f 0c 00 00       	call   80101db5 <stati>
    iunlock(f->ip);
80101136:	8b 45 08             	mov    0x8(%ebp),%eax
80101139:	8b 40 10             	mov    0x10(%eax),%eax
8010113c:	89 04 24             	mov    %eax,(%esp)
8010113f:	e8 26 09 00 00       	call   80101a6a <iunlock>
    return 0;
80101144:	b8 00 00 00 00       	mov    $0x0,%eax
80101149:	eb 05                	jmp    80101150 <filestat+0x4d>
  }
  return -1;
8010114b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80101150:	c9                   	leave  
80101151:	c3                   	ret    

80101152 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80101152:	55                   	push   %ebp
80101153:	89 e5                	mov    %esp,%ebp
80101155:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
80101158:	8b 45 08             	mov    0x8(%ebp),%eax
8010115b:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010115f:	84 c0                	test   %al,%al
80101161:	75 0a                	jne    8010116d <fileread+0x1b>
    return -1;
80101163:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101168:	e9 9f 00 00 00       	jmp    8010120c <fileread+0xba>
  if(f->type == FD_PIPE)
8010116d:	8b 45 08             	mov    0x8(%ebp),%eax
80101170:	8b 00                	mov    (%eax),%eax
80101172:	83 f8 01             	cmp    $0x1,%eax
80101175:	75 1e                	jne    80101195 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101177:	8b 45 08             	mov    0x8(%ebp),%eax
8010117a:	8b 40 0c             	mov    0xc(%eax),%eax
8010117d:	8b 55 10             	mov    0x10(%ebp),%edx
80101180:	89 54 24 08          	mov    %edx,0x8(%esp)
80101184:	8b 55 0c             	mov    0xc(%ebp),%edx
80101187:	89 54 24 04          	mov    %edx,0x4(%esp)
8010118b:	89 04 24             	mov    %eax,(%esp)
8010118e:	e8 15 2e 00 00       	call   80103fa8 <piperead>
80101193:	eb 77                	jmp    8010120c <fileread+0xba>
  if(f->type == FD_INODE){
80101195:	8b 45 08             	mov    0x8(%ebp),%eax
80101198:	8b 00                	mov    (%eax),%eax
8010119a:	83 f8 02             	cmp    $0x2,%eax
8010119d:	75 61                	jne    80101200 <fileread+0xae>
    ilock(f->ip);
8010119f:	8b 45 08             	mov    0x8(%ebp),%eax
801011a2:	8b 40 10             	mov    0x10(%eax),%eax
801011a5:	89 04 24             	mov    %eax,(%esp)
801011a8:	e8 b0 07 00 00       	call   8010195d <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
801011ad:	8b 4d 10             	mov    0x10(%ebp),%ecx
801011b0:	8b 45 08             	mov    0x8(%ebp),%eax
801011b3:	8b 50 14             	mov    0x14(%eax),%edx
801011b6:	8b 45 08             	mov    0x8(%ebp),%eax
801011b9:	8b 40 10             	mov    0x10(%eax),%eax
801011bc:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801011c0:	89 54 24 08          	mov    %edx,0x8(%esp)
801011c4:	8b 55 0c             	mov    0xc(%ebp),%edx
801011c7:	89 54 24 04          	mov    %edx,0x4(%esp)
801011cb:	89 04 24             	mov    %eax,(%esp)
801011ce:	e8 27 0c 00 00       	call   80101dfa <readi>
801011d3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801011d6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801011da:	7e 11                	jle    801011ed <fileread+0x9b>
      f->off += r;
801011dc:	8b 45 08             	mov    0x8(%ebp),%eax
801011df:	8b 50 14             	mov    0x14(%eax),%edx
801011e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011e5:	01 c2                	add    %eax,%edx
801011e7:	8b 45 08             	mov    0x8(%ebp),%eax
801011ea:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
801011ed:	8b 45 08             	mov    0x8(%ebp),%eax
801011f0:	8b 40 10             	mov    0x10(%eax),%eax
801011f3:	89 04 24             	mov    %eax,(%esp)
801011f6:	e8 6f 08 00 00       	call   80101a6a <iunlock>
    return r;
801011fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011fe:	eb 0c                	jmp    8010120c <fileread+0xba>
  }
  panic("fileread");
80101200:	c7 04 24 fb 84 10 80 	movl   $0x801084fb,(%esp)
80101207:	e8 56 f3 ff ff       	call   80100562 <panic>
}
8010120c:	c9                   	leave  
8010120d:	c3                   	ret    

8010120e <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
8010120e:	55                   	push   %ebp
8010120f:	89 e5                	mov    %esp,%ebp
80101211:	53                   	push   %ebx
80101212:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
80101215:	8b 45 08             	mov    0x8(%ebp),%eax
80101218:	0f b6 40 09          	movzbl 0x9(%eax),%eax
8010121c:	84 c0                	test   %al,%al
8010121e:	75 0a                	jne    8010122a <filewrite+0x1c>
    return -1;
80101220:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101225:	e9 20 01 00 00       	jmp    8010134a <filewrite+0x13c>
  if(f->type == FD_PIPE)
8010122a:	8b 45 08             	mov    0x8(%ebp),%eax
8010122d:	8b 00                	mov    (%eax),%eax
8010122f:	83 f8 01             	cmp    $0x1,%eax
80101232:	75 21                	jne    80101255 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
80101234:	8b 45 08             	mov    0x8(%ebp),%eax
80101237:	8b 40 0c             	mov    0xc(%eax),%eax
8010123a:	8b 55 10             	mov    0x10(%ebp),%edx
8010123d:	89 54 24 08          	mov    %edx,0x8(%esp)
80101241:	8b 55 0c             	mov    0xc(%ebp),%edx
80101244:	89 54 24 04          	mov    %edx,0x4(%esp)
80101248:	89 04 24             	mov    %eax,(%esp)
8010124b:	e8 6a 2c 00 00       	call   80103eba <pipewrite>
80101250:	e9 f5 00 00 00       	jmp    8010134a <filewrite+0x13c>
  if(f->type == FD_INODE){
80101255:	8b 45 08             	mov    0x8(%ebp),%eax
80101258:	8b 00                	mov    (%eax),%eax
8010125a:	83 f8 02             	cmp    $0x2,%eax
8010125d:	0f 85 db 00 00 00    	jne    8010133e <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
80101263:	c7 45 ec 00 06 00 00 	movl   $0x600,-0x14(%ebp)
    int i = 0;
8010126a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101271:	e9 a8 00 00 00       	jmp    8010131e <filewrite+0x110>
      int n1 = n - i;
80101276:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101279:	8b 55 10             	mov    0x10(%ebp),%edx
8010127c:	29 c2                	sub    %eax,%edx
8010127e:	89 d0                	mov    %edx,%eax
80101280:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101283:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101286:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80101289:	7e 06                	jle    80101291 <filewrite+0x83>
        n1 = max;
8010128b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010128e:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101291:	e8 f1 21 00 00       	call   80103487 <begin_op>
      ilock(f->ip);
80101296:	8b 45 08             	mov    0x8(%ebp),%eax
80101299:	8b 40 10             	mov    0x10(%eax),%eax
8010129c:	89 04 24             	mov    %eax,(%esp)
8010129f:	e8 b9 06 00 00       	call   8010195d <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
801012a4:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801012a7:	8b 45 08             	mov    0x8(%ebp),%eax
801012aa:	8b 50 14             	mov    0x14(%eax),%edx
801012ad:	8b 5d f4             	mov    -0xc(%ebp),%ebx
801012b0:	8b 45 0c             	mov    0xc(%ebp),%eax
801012b3:	01 c3                	add    %eax,%ebx
801012b5:	8b 45 08             	mov    0x8(%ebp),%eax
801012b8:	8b 40 10             	mov    0x10(%eax),%eax
801012bb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801012bf:	89 54 24 08          	mov    %edx,0x8(%esp)
801012c3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
801012c7:	89 04 24             	mov    %eax,(%esp)
801012ca:	e8 8f 0c 00 00       	call   80101f5e <writei>
801012cf:	89 45 e8             	mov    %eax,-0x18(%ebp)
801012d2:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801012d6:	7e 11                	jle    801012e9 <filewrite+0xdb>
        f->off += r;
801012d8:	8b 45 08             	mov    0x8(%ebp),%eax
801012db:	8b 50 14             	mov    0x14(%eax),%edx
801012de:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012e1:	01 c2                	add    %eax,%edx
801012e3:	8b 45 08             	mov    0x8(%ebp),%eax
801012e6:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
801012e9:	8b 45 08             	mov    0x8(%ebp),%eax
801012ec:	8b 40 10             	mov    0x10(%eax),%eax
801012ef:	89 04 24             	mov    %eax,(%esp)
801012f2:	e8 73 07 00 00       	call   80101a6a <iunlock>
      end_op();
801012f7:	e8 0f 22 00 00       	call   8010350b <end_op>

      if(r < 0)
801012fc:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101300:	79 02                	jns    80101304 <filewrite+0xf6>
        break;
80101302:	eb 26                	jmp    8010132a <filewrite+0x11c>
      if(r != n1)
80101304:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101307:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010130a:	74 0c                	je     80101318 <filewrite+0x10a>
        panic("short filewrite");
8010130c:	c7 04 24 04 85 10 80 	movl   $0x80108504,(%esp)
80101313:	e8 4a f2 ff ff       	call   80100562 <panic>
      i += r;
80101318:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010131b:	01 45 f4             	add    %eax,-0xc(%ebp)
    while(i < n){
8010131e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101321:	3b 45 10             	cmp    0x10(%ebp),%eax
80101324:	0f 8c 4c ff ff ff    	jl     80101276 <filewrite+0x68>
    }
    return i == n ? n : -1;
8010132a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010132d:	3b 45 10             	cmp    0x10(%ebp),%eax
80101330:	75 05                	jne    80101337 <filewrite+0x129>
80101332:	8b 45 10             	mov    0x10(%ebp),%eax
80101335:	eb 05                	jmp    8010133c <filewrite+0x12e>
80101337:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010133c:	eb 0c                	jmp    8010134a <filewrite+0x13c>
  }
  panic("filewrite");
8010133e:	c7 04 24 14 85 10 80 	movl   $0x80108514,(%esp)
80101345:	e8 18 f2 ff ff       	call   80100562 <panic>
}
8010134a:	83 c4 24             	add    $0x24,%esp
8010134d:	5b                   	pop    %ebx
8010134e:	5d                   	pop    %ebp
8010134f:	c3                   	ret    

80101350 <readsb>:
struct superblock sb; 

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101350:	55                   	push   %ebp
80101351:	89 e5                	mov    %esp,%ebp
80101353:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;

  bp = bread(dev, 1);
80101356:	8b 45 08             	mov    0x8(%ebp),%eax
80101359:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101360:	00 
80101361:	89 04 24             	mov    %eax,(%esp)
80101364:	e8 4c ee ff ff       	call   801001b5 <bread>
80101369:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
8010136c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010136f:	83 c0 5c             	add    $0x5c,%eax
80101372:	c7 44 24 08 1c 00 00 	movl   $0x1c,0x8(%esp)
80101379:	00 
8010137a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010137e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101381:	89 04 24             	mov    %eax,(%esp)
80101384:	e8 98 3f 00 00       	call   80105321 <memmove>
  brelse(bp);
80101389:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010138c:	89 04 24             	mov    %eax,(%esp)
8010138f:	e8 98 ee ff ff       	call   8010022c <brelse>
}
80101394:	c9                   	leave  
80101395:	c3                   	ret    

80101396 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101396:	55                   	push   %ebp
80101397:	89 e5                	mov    %esp,%ebp
80101399:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;

  bp = bread(dev, bno);
8010139c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010139f:	8b 45 08             	mov    0x8(%ebp),%eax
801013a2:	89 54 24 04          	mov    %edx,0x4(%esp)
801013a6:	89 04 24             	mov    %eax,(%esp)
801013a9:	e8 07 ee ff ff       	call   801001b5 <bread>
801013ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
801013b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013b4:	83 c0 5c             	add    $0x5c,%eax
801013b7:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801013be:	00 
801013bf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801013c6:	00 
801013c7:	89 04 24             	mov    %eax,(%esp)
801013ca:	e8 83 3e 00 00       	call   80105252 <memset>
  log_write(bp);
801013cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013d2:	89 04 24             	mov    %eax,(%esp)
801013d5:	e8 b8 22 00 00       	call   80103692 <log_write>
  brelse(bp);
801013da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013dd:	89 04 24             	mov    %eax,(%esp)
801013e0:	e8 47 ee ff ff       	call   8010022c <brelse>
}
801013e5:	c9                   	leave  
801013e6:	c3                   	ret    

801013e7 <balloc>:
// Blocks.

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801013e7:	55                   	push   %ebp
801013e8:	89 e5                	mov    %esp,%ebp
801013ea:	83 ec 28             	sub    $0x28,%esp
  int b, bi, m;
  struct buf *bp;

  bp = 0;
801013ed:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  for(b = 0; b < sb.size; b += BPB){
801013f4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801013fb:	e9 07 01 00 00       	jmp    80101507 <balloc+0x120>
    bp = bread(dev, BBLOCK(b, sb));
80101400:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101403:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
80101409:	85 c0                	test   %eax,%eax
8010140b:	0f 48 c2             	cmovs  %edx,%eax
8010140e:	c1 f8 0c             	sar    $0xc,%eax
80101411:	89 c2                	mov    %eax,%edx
80101413:	a1 58 1a 11 80       	mov    0x80111a58,%eax
80101418:	01 d0                	add    %edx,%eax
8010141a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010141e:	8b 45 08             	mov    0x8(%ebp),%eax
80101421:	89 04 24             	mov    %eax,(%esp)
80101424:	e8 8c ed ff ff       	call   801001b5 <bread>
80101429:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010142c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101433:	e9 9d 00 00 00       	jmp    801014d5 <balloc+0xee>
      m = 1 << (bi % 8);
80101438:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010143b:	99                   	cltd   
8010143c:	c1 ea 1d             	shr    $0x1d,%edx
8010143f:	01 d0                	add    %edx,%eax
80101441:	83 e0 07             	and    $0x7,%eax
80101444:	29 d0                	sub    %edx,%eax
80101446:	ba 01 00 00 00       	mov    $0x1,%edx
8010144b:	89 c1                	mov    %eax,%ecx
8010144d:	d3 e2                	shl    %cl,%edx
8010144f:	89 d0                	mov    %edx,%eax
80101451:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101454:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101457:	8d 50 07             	lea    0x7(%eax),%edx
8010145a:	85 c0                	test   %eax,%eax
8010145c:	0f 48 c2             	cmovs  %edx,%eax
8010145f:	c1 f8 03             	sar    $0x3,%eax
80101462:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101465:	0f b6 44 02 5c       	movzbl 0x5c(%edx,%eax,1),%eax
8010146a:	0f b6 c0             	movzbl %al,%eax
8010146d:	23 45 e8             	and    -0x18(%ebp),%eax
80101470:	85 c0                	test   %eax,%eax
80101472:	75 5d                	jne    801014d1 <balloc+0xea>
        bp->data[bi/8] |= m;  // Mark block in use.
80101474:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101477:	8d 50 07             	lea    0x7(%eax),%edx
8010147a:	85 c0                	test   %eax,%eax
8010147c:	0f 48 c2             	cmovs  %edx,%eax
8010147f:	c1 f8 03             	sar    $0x3,%eax
80101482:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101485:	0f b6 54 02 5c       	movzbl 0x5c(%edx,%eax,1),%edx
8010148a:	89 d1                	mov    %edx,%ecx
8010148c:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010148f:	09 ca                	or     %ecx,%edx
80101491:	89 d1                	mov    %edx,%ecx
80101493:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101496:	88 4c 02 5c          	mov    %cl,0x5c(%edx,%eax,1)
        log_write(bp);
8010149a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010149d:	89 04 24             	mov    %eax,(%esp)
801014a0:	e8 ed 21 00 00       	call   80103692 <log_write>
        brelse(bp);
801014a5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014a8:	89 04 24             	mov    %eax,(%esp)
801014ab:	e8 7c ed ff ff       	call   8010022c <brelse>
        bzero(dev, b + bi);
801014b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014b3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014b6:	01 c2                	add    %eax,%edx
801014b8:	8b 45 08             	mov    0x8(%ebp),%eax
801014bb:	89 54 24 04          	mov    %edx,0x4(%esp)
801014bf:	89 04 24             	mov    %eax,(%esp)
801014c2:	e8 cf fe ff ff       	call   80101396 <bzero>
        return b + bi;
801014c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014ca:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014cd:	01 d0                	add    %edx,%eax
801014cf:	eb 52                	jmp    80101523 <balloc+0x13c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014d1:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801014d5:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
801014dc:	7f 17                	jg     801014f5 <balloc+0x10e>
801014de:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014e1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014e4:	01 d0                	add    %edx,%eax
801014e6:	89 c2                	mov    %eax,%edx
801014e8:	a1 40 1a 11 80       	mov    0x80111a40,%eax
801014ed:	39 c2                	cmp    %eax,%edx
801014ef:	0f 82 43 ff ff ff    	jb     80101438 <balloc+0x51>
      }
    }
    brelse(bp);
801014f5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014f8:	89 04 24             	mov    %eax,(%esp)
801014fb:	e8 2c ed ff ff       	call   8010022c <brelse>
  for(b = 0; b < sb.size; b += BPB){
80101500:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80101507:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010150a:	a1 40 1a 11 80       	mov    0x80111a40,%eax
8010150f:	39 c2                	cmp    %eax,%edx
80101511:	0f 82 e9 fe ff ff    	jb     80101400 <balloc+0x19>
  }
  panic("balloc: out of blocks");
80101517:	c7 04 24 20 85 10 80 	movl   $0x80108520,(%esp)
8010151e:	e8 3f f0 ff ff       	call   80100562 <panic>
}
80101523:	c9                   	leave  
80101524:	c3                   	ret    

80101525 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
80101525:	55                   	push   %ebp
80101526:	89 e5                	mov    %esp,%ebp
80101528:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  int bi, m;

  readsb(dev, &sb);
8010152b:	c7 44 24 04 40 1a 11 	movl   $0x80111a40,0x4(%esp)
80101532:	80 
80101533:	8b 45 08             	mov    0x8(%ebp),%eax
80101536:	89 04 24             	mov    %eax,(%esp)
80101539:	e8 12 fe ff ff       	call   80101350 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
8010153e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101541:	c1 e8 0c             	shr    $0xc,%eax
80101544:	89 c2                	mov    %eax,%edx
80101546:	a1 58 1a 11 80       	mov    0x80111a58,%eax
8010154b:	01 c2                	add    %eax,%edx
8010154d:	8b 45 08             	mov    0x8(%ebp),%eax
80101550:	89 54 24 04          	mov    %edx,0x4(%esp)
80101554:	89 04 24             	mov    %eax,(%esp)
80101557:	e8 59 ec ff ff       	call   801001b5 <bread>
8010155c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
8010155f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101562:	25 ff 0f 00 00       	and    $0xfff,%eax
80101567:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010156a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010156d:	99                   	cltd   
8010156e:	c1 ea 1d             	shr    $0x1d,%edx
80101571:	01 d0                	add    %edx,%eax
80101573:	83 e0 07             	and    $0x7,%eax
80101576:	29 d0                	sub    %edx,%eax
80101578:	ba 01 00 00 00       	mov    $0x1,%edx
8010157d:	89 c1                	mov    %eax,%ecx
8010157f:	d3 e2                	shl    %cl,%edx
80101581:	89 d0                	mov    %edx,%eax
80101583:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101586:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101589:	8d 50 07             	lea    0x7(%eax),%edx
8010158c:	85 c0                	test   %eax,%eax
8010158e:	0f 48 c2             	cmovs  %edx,%eax
80101591:	c1 f8 03             	sar    $0x3,%eax
80101594:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101597:	0f b6 44 02 5c       	movzbl 0x5c(%edx,%eax,1),%eax
8010159c:	0f b6 c0             	movzbl %al,%eax
8010159f:	23 45 ec             	and    -0x14(%ebp),%eax
801015a2:	85 c0                	test   %eax,%eax
801015a4:	75 0c                	jne    801015b2 <bfree+0x8d>
    panic("freeing free block");
801015a6:	c7 04 24 36 85 10 80 	movl   $0x80108536,(%esp)
801015ad:	e8 b0 ef ff ff       	call   80100562 <panic>
  bp->data[bi/8] &= ~m;
801015b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015b5:	8d 50 07             	lea    0x7(%eax),%edx
801015b8:	85 c0                	test   %eax,%eax
801015ba:	0f 48 c2             	cmovs  %edx,%eax
801015bd:	c1 f8 03             	sar    $0x3,%eax
801015c0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015c3:	0f b6 54 02 5c       	movzbl 0x5c(%edx,%eax,1),%edx
801015c8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
801015cb:	f7 d1                	not    %ecx
801015cd:	21 ca                	and    %ecx,%edx
801015cf:	89 d1                	mov    %edx,%ecx
801015d1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015d4:	88 4c 02 5c          	mov    %cl,0x5c(%edx,%eax,1)
  log_write(bp);
801015d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015db:	89 04 24             	mov    %eax,(%esp)
801015de:	e8 af 20 00 00       	call   80103692 <log_write>
  brelse(bp);
801015e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015e6:	89 04 24             	mov    %eax,(%esp)
801015e9:	e8 3e ec ff ff       	call   8010022c <brelse>
}
801015ee:	c9                   	leave  
801015ef:	c3                   	ret    

801015f0 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(int dev)
{
801015f0:	55                   	push   %ebp
801015f1:	89 e5                	mov    %esp,%ebp
801015f3:	57                   	push   %edi
801015f4:	56                   	push   %esi
801015f5:	53                   	push   %ebx
801015f6:	83 ec 4c             	sub    $0x4c,%esp
  int i = 0;
801015f9:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  
  initlock(&icache.lock, "icache");
80101600:	c7 44 24 04 49 85 10 	movl   $0x80108549,0x4(%esp)
80101607:	80 
80101608:	c7 04 24 60 1a 11 80 	movl   $0x80111a60,(%esp)
8010160f:	e8 ab 39 00 00       	call   80104fbf <initlock>
  for(i = 0; i < NINODE; i++) {
80101614:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010161b:	eb 2c                	jmp    80101649 <iinit+0x59>
    initsleeplock(&icache.inode[i].lock, "inode");
8010161d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101620:	89 d0                	mov    %edx,%eax
80101622:	c1 e0 03             	shl    $0x3,%eax
80101625:	01 d0                	add    %edx,%eax
80101627:	c1 e0 04             	shl    $0x4,%eax
8010162a:	83 c0 30             	add    $0x30,%eax
8010162d:	05 60 1a 11 80       	add    $0x80111a60,%eax
80101632:	83 c0 10             	add    $0x10,%eax
80101635:	c7 44 24 04 50 85 10 	movl   $0x80108550,0x4(%esp)
8010163c:	80 
8010163d:	89 04 24             	mov    %eax,(%esp)
80101640:	e8 17 38 00 00       	call   80104e5c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
80101645:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80101649:	83 7d e4 31          	cmpl   $0x31,-0x1c(%ebp)
8010164d:	7e ce                	jle    8010161d <iinit+0x2d>
  }

  readsb(dev, &sb);
8010164f:	c7 44 24 04 40 1a 11 	movl   $0x80111a40,0x4(%esp)
80101656:	80 
80101657:	8b 45 08             	mov    0x8(%ebp),%eax
8010165a:	89 04 24             	mov    %eax,(%esp)
8010165d:	e8 ee fc ff ff       	call   80101350 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
80101662:	a1 58 1a 11 80       	mov    0x80111a58,%eax
80101667:	8b 3d 54 1a 11 80    	mov    0x80111a54,%edi
8010166d:	8b 35 50 1a 11 80    	mov    0x80111a50,%esi
80101673:	8b 1d 4c 1a 11 80    	mov    0x80111a4c,%ebx
80101679:	8b 0d 48 1a 11 80    	mov    0x80111a48,%ecx
8010167f:	8b 15 44 1a 11 80    	mov    0x80111a44,%edx
80101685:	89 55 d4             	mov    %edx,-0x2c(%ebp)
80101688:	8b 15 40 1a 11 80    	mov    0x80111a40,%edx
8010168e:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101692:	89 7c 24 18          	mov    %edi,0x18(%esp)
80101696:	89 74 24 14          	mov    %esi,0x14(%esp)
8010169a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010169e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801016a2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801016a5:	89 44 24 08          	mov    %eax,0x8(%esp)
801016a9:	89 d0                	mov    %edx,%eax
801016ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801016af:	c7 04 24 58 85 10 80 	movl   $0x80108558,(%esp)
801016b6:	e8 0d ed ff ff       	call   801003c8 <cprintf>
 inodestart %d bmap start %d\n", sb.size, sb.nblocks,
          sb.ninodes, sb.nlog, sb.logstart, sb.inodestart,
          sb.bmapstart);
}
801016bb:	83 c4 4c             	add    $0x4c,%esp
801016be:	5b                   	pop    %ebx
801016bf:	5e                   	pop    %esi
801016c0:	5f                   	pop    %edi
801016c1:	5d                   	pop    %ebp
801016c2:	c3                   	ret    

801016c3 <ialloc>:
// Allocate an inode on device dev.
// Mark it as allocated by  giving it type type.
// Returns an unlocked but allocated and referenced inode.
struct inode*
ialloc(uint dev, short type)
{
801016c3:	55                   	push   %ebp
801016c4:	89 e5                	mov    %esp,%ebp
801016c6:	83 ec 28             	sub    $0x28,%esp
801016c9:	8b 45 0c             	mov    0xc(%ebp),%eax
801016cc:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
801016d0:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
801016d7:	e9 9e 00 00 00       	jmp    8010177a <ialloc+0xb7>
    bp = bread(dev, IBLOCK(inum, sb));
801016dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016df:	c1 e8 03             	shr    $0x3,%eax
801016e2:	89 c2                	mov    %eax,%edx
801016e4:	a1 54 1a 11 80       	mov    0x80111a54,%eax
801016e9:	01 d0                	add    %edx,%eax
801016eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801016ef:	8b 45 08             	mov    0x8(%ebp),%eax
801016f2:	89 04 24             	mov    %eax,(%esp)
801016f5:	e8 bb ea ff ff       	call   801001b5 <bread>
801016fa:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
801016fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101700:	8d 50 5c             	lea    0x5c(%eax),%edx
80101703:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101706:	83 e0 07             	and    $0x7,%eax
80101709:	c1 e0 06             	shl    $0x6,%eax
8010170c:	01 d0                	add    %edx,%eax
8010170e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101711:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101714:	0f b7 00             	movzwl (%eax),%eax
80101717:	66 85 c0             	test   %ax,%ax
8010171a:	75 4f                	jne    8010176b <ialloc+0xa8>
      memset(dip, 0, sizeof(*dip));
8010171c:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
80101723:	00 
80101724:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010172b:	00 
8010172c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010172f:	89 04 24             	mov    %eax,(%esp)
80101732:	e8 1b 3b 00 00       	call   80105252 <memset>
      dip->type = type;
80101737:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010173a:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
8010173e:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101741:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101744:	89 04 24             	mov    %eax,(%esp)
80101747:	e8 46 1f 00 00       	call   80103692 <log_write>
      brelse(bp);
8010174c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010174f:	89 04 24             	mov    %eax,(%esp)
80101752:	e8 d5 ea ff ff       	call   8010022c <brelse>
      return iget(dev, inum);
80101757:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010175a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010175e:	8b 45 08             	mov    0x8(%ebp),%eax
80101761:	89 04 24             	mov    %eax,(%esp)
80101764:	e8 ed 00 00 00       	call   80101856 <iget>
80101769:	eb 2b                	jmp    80101796 <ialloc+0xd3>
    }
    brelse(bp);
8010176b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010176e:	89 04 24             	mov    %eax,(%esp)
80101771:	e8 b6 ea ff ff       	call   8010022c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
80101776:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010177a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010177d:	a1 48 1a 11 80       	mov    0x80111a48,%eax
80101782:	39 c2                	cmp    %eax,%edx
80101784:	0f 82 52 ff ff ff    	jb     801016dc <ialloc+0x19>
  }
  panic("ialloc: no inodes");
8010178a:	c7 04 24 ab 85 10 80 	movl   $0x801085ab,(%esp)
80101791:	e8 cc ed ff ff       	call   80100562 <panic>
}
80101796:	c9                   	leave  
80101797:	c3                   	ret    

80101798 <iupdate>:
// Must be called after every change to an ip->xxx field
// that lives on disk, since i-node cache is write-through.
// Caller must hold ip->lock.
void
iupdate(struct inode *ip)
{
80101798:	55                   	push   %ebp
80101799:	89 e5                	mov    %esp,%ebp
8010179b:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
8010179e:	8b 45 08             	mov    0x8(%ebp),%eax
801017a1:	8b 40 04             	mov    0x4(%eax),%eax
801017a4:	c1 e8 03             	shr    $0x3,%eax
801017a7:	89 c2                	mov    %eax,%edx
801017a9:	a1 54 1a 11 80       	mov    0x80111a54,%eax
801017ae:	01 c2                	add    %eax,%edx
801017b0:	8b 45 08             	mov    0x8(%ebp),%eax
801017b3:	8b 00                	mov    (%eax),%eax
801017b5:	89 54 24 04          	mov    %edx,0x4(%esp)
801017b9:	89 04 24             	mov    %eax,(%esp)
801017bc:	e8 f4 e9 ff ff       	call   801001b5 <bread>
801017c1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801017c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017c7:	8d 50 5c             	lea    0x5c(%eax),%edx
801017ca:	8b 45 08             	mov    0x8(%ebp),%eax
801017cd:	8b 40 04             	mov    0x4(%eax),%eax
801017d0:	83 e0 07             	and    $0x7,%eax
801017d3:	c1 e0 06             	shl    $0x6,%eax
801017d6:	01 d0                	add    %edx,%eax
801017d8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
801017db:	8b 45 08             	mov    0x8(%ebp),%eax
801017de:	0f b7 50 50          	movzwl 0x50(%eax),%edx
801017e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017e5:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801017e8:	8b 45 08             	mov    0x8(%ebp),%eax
801017eb:	0f b7 50 52          	movzwl 0x52(%eax),%edx
801017ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017f2:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801017f6:	8b 45 08             	mov    0x8(%ebp),%eax
801017f9:	0f b7 50 54          	movzwl 0x54(%eax),%edx
801017fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101800:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101804:	8b 45 08             	mov    0x8(%ebp),%eax
80101807:	0f b7 50 56          	movzwl 0x56(%eax),%edx
8010180b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010180e:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101812:	8b 45 08             	mov    0x8(%ebp),%eax
80101815:	8b 50 58             	mov    0x58(%eax),%edx
80101818:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010181b:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
8010181e:	8b 45 08             	mov    0x8(%ebp),%eax
80101821:	8d 50 5c             	lea    0x5c(%eax),%edx
80101824:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101827:	83 c0 0c             	add    $0xc,%eax
8010182a:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101831:	00 
80101832:	89 54 24 04          	mov    %edx,0x4(%esp)
80101836:	89 04 24             	mov    %eax,(%esp)
80101839:	e8 e3 3a 00 00       	call   80105321 <memmove>
  log_write(bp);
8010183e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101841:	89 04 24             	mov    %eax,(%esp)
80101844:	e8 49 1e 00 00       	call   80103692 <log_write>
  brelse(bp);
80101849:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010184c:	89 04 24             	mov    %eax,(%esp)
8010184f:	e8 d8 e9 ff ff       	call   8010022c <brelse>
}
80101854:	c9                   	leave  
80101855:	c3                   	ret    

80101856 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80101856:	55                   	push   %ebp
80101857:	89 e5                	mov    %esp,%ebp
80101859:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
8010185c:	c7 04 24 60 1a 11 80 	movl   $0x80111a60,(%esp)
80101863:	e8 78 37 00 00       	call   80104fe0 <acquire>

  // Is the inode already cached?
  empty = 0;
80101868:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010186f:	c7 45 f4 94 1a 11 80 	movl   $0x80111a94,-0xc(%ebp)
80101876:	eb 5c                	jmp    801018d4 <iget+0x7e>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101878:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010187b:	8b 40 08             	mov    0x8(%eax),%eax
8010187e:	85 c0                	test   %eax,%eax
80101880:	7e 35                	jle    801018b7 <iget+0x61>
80101882:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101885:	8b 00                	mov    (%eax),%eax
80101887:	3b 45 08             	cmp    0x8(%ebp),%eax
8010188a:	75 2b                	jne    801018b7 <iget+0x61>
8010188c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010188f:	8b 40 04             	mov    0x4(%eax),%eax
80101892:	3b 45 0c             	cmp    0xc(%ebp),%eax
80101895:	75 20                	jne    801018b7 <iget+0x61>
      ip->ref++;
80101897:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010189a:	8b 40 08             	mov    0x8(%eax),%eax
8010189d:	8d 50 01             	lea    0x1(%eax),%edx
801018a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018a3:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
801018a6:	c7 04 24 60 1a 11 80 	movl   $0x80111a60,(%esp)
801018ad:	e8 96 37 00 00       	call   80105048 <release>
      return ip;
801018b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018b5:	eb 72                	jmp    80101929 <iget+0xd3>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801018b7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801018bb:	75 10                	jne    801018cd <iget+0x77>
801018bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018c0:	8b 40 08             	mov    0x8(%eax),%eax
801018c3:	85 c0                	test   %eax,%eax
801018c5:	75 06                	jne    801018cd <iget+0x77>
      empty = ip;
801018c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018ca:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801018cd:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
801018d4:	81 7d f4 b4 36 11 80 	cmpl   $0x801136b4,-0xc(%ebp)
801018db:	72 9b                	jb     80101878 <iget+0x22>
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801018dd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801018e1:	75 0c                	jne    801018ef <iget+0x99>
    panic("iget: no inodes");
801018e3:	c7 04 24 bd 85 10 80 	movl   $0x801085bd,(%esp)
801018ea:	e8 73 ec ff ff       	call   80100562 <panic>

  ip = empty;
801018ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018f2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
801018f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018f8:	8b 55 08             	mov    0x8(%ebp),%edx
801018fb:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
801018fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101900:	8b 55 0c             	mov    0xc(%ebp),%edx
80101903:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101906:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101909:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->valid = 0;
80101910:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101913:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  release(&icache.lock);
8010191a:	c7 04 24 60 1a 11 80 	movl   $0x80111a60,(%esp)
80101921:	e8 22 37 00 00       	call   80105048 <release>

  return ip;
80101926:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101929:	c9                   	leave  
8010192a:	c3                   	ret    

8010192b <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
8010192b:	55                   	push   %ebp
8010192c:	89 e5                	mov    %esp,%ebp
8010192e:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101931:	c7 04 24 60 1a 11 80 	movl   $0x80111a60,(%esp)
80101938:	e8 a3 36 00 00       	call   80104fe0 <acquire>
  ip->ref++;
8010193d:	8b 45 08             	mov    0x8(%ebp),%eax
80101940:	8b 40 08             	mov    0x8(%eax),%eax
80101943:	8d 50 01             	lea    0x1(%eax),%edx
80101946:	8b 45 08             	mov    0x8(%ebp),%eax
80101949:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010194c:	c7 04 24 60 1a 11 80 	movl   $0x80111a60,(%esp)
80101953:	e8 f0 36 00 00       	call   80105048 <release>
  return ip;
80101958:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010195b:	c9                   	leave  
8010195c:	c3                   	ret    

8010195d <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
8010195d:	55                   	push   %ebp
8010195e:	89 e5                	mov    %esp,%ebp
80101960:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101963:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101967:	74 0a                	je     80101973 <ilock+0x16>
80101969:	8b 45 08             	mov    0x8(%ebp),%eax
8010196c:	8b 40 08             	mov    0x8(%eax),%eax
8010196f:	85 c0                	test   %eax,%eax
80101971:	7f 0c                	jg     8010197f <ilock+0x22>
    panic("ilock");
80101973:	c7 04 24 cd 85 10 80 	movl   $0x801085cd,(%esp)
8010197a:	e8 e3 eb ff ff       	call   80100562 <panic>

  acquiresleep(&ip->lock);
8010197f:	8b 45 08             	mov    0x8(%ebp),%eax
80101982:	83 c0 0c             	add    $0xc,%eax
80101985:	89 04 24             	mov    %eax,(%esp)
80101988:	e8 09 35 00 00       	call   80104e96 <acquiresleep>

  if(ip->valid == 0){
8010198d:	8b 45 08             	mov    0x8(%ebp),%eax
80101990:	8b 40 4c             	mov    0x4c(%eax),%eax
80101993:	85 c0                	test   %eax,%eax
80101995:	0f 85 cd 00 00 00    	jne    80101a68 <ilock+0x10b>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
8010199b:	8b 45 08             	mov    0x8(%ebp),%eax
8010199e:	8b 40 04             	mov    0x4(%eax),%eax
801019a1:	c1 e8 03             	shr    $0x3,%eax
801019a4:	89 c2                	mov    %eax,%edx
801019a6:	a1 54 1a 11 80       	mov    0x80111a54,%eax
801019ab:	01 c2                	add    %eax,%edx
801019ad:	8b 45 08             	mov    0x8(%ebp),%eax
801019b0:	8b 00                	mov    (%eax),%eax
801019b2:	89 54 24 04          	mov    %edx,0x4(%esp)
801019b6:	89 04 24             	mov    %eax,(%esp)
801019b9:	e8 f7 e7 ff ff       	call   801001b5 <bread>
801019be:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801019c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019c4:	8d 50 5c             	lea    0x5c(%eax),%edx
801019c7:	8b 45 08             	mov    0x8(%ebp),%eax
801019ca:	8b 40 04             	mov    0x4(%eax),%eax
801019cd:	83 e0 07             	and    $0x7,%eax
801019d0:	c1 e0 06             	shl    $0x6,%eax
801019d3:	01 d0                	add    %edx,%eax
801019d5:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
801019d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019db:	0f b7 10             	movzwl (%eax),%edx
801019de:	8b 45 08             	mov    0x8(%ebp),%eax
801019e1:	66 89 50 50          	mov    %dx,0x50(%eax)
    ip->major = dip->major;
801019e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019e8:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801019ec:	8b 45 08             	mov    0x8(%ebp),%eax
801019ef:	66 89 50 52          	mov    %dx,0x52(%eax)
    ip->minor = dip->minor;
801019f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019f6:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801019fa:	8b 45 08             	mov    0x8(%ebp),%eax
801019fd:	66 89 50 54          	mov    %dx,0x54(%eax)
    ip->nlink = dip->nlink;
80101a01:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a04:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101a08:	8b 45 08             	mov    0x8(%ebp),%eax
80101a0b:	66 89 50 56          	mov    %dx,0x56(%eax)
    ip->size = dip->size;
80101a0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a12:	8b 50 08             	mov    0x8(%eax),%edx
80101a15:	8b 45 08             	mov    0x8(%ebp),%eax
80101a18:	89 50 58             	mov    %edx,0x58(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101a1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a1e:	8d 50 0c             	lea    0xc(%eax),%edx
80101a21:	8b 45 08             	mov    0x8(%ebp),%eax
80101a24:	83 c0 5c             	add    $0x5c,%eax
80101a27:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101a2e:	00 
80101a2f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a33:	89 04 24             	mov    %eax,(%esp)
80101a36:	e8 e6 38 00 00       	call   80105321 <memmove>
    brelse(bp);
80101a3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a3e:	89 04 24             	mov    %eax,(%esp)
80101a41:	e8 e6 e7 ff ff       	call   8010022c <brelse>
    ip->valid = 1;
80101a46:	8b 45 08             	mov    0x8(%ebp),%eax
80101a49:	c7 40 4c 01 00 00 00 	movl   $0x1,0x4c(%eax)
    if(ip->type == 0)
80101a50:	8b 45 08             	mov    0x8(%ebp),%eax
80101a53:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80101a57:	66 85 c0             	test   %ax,%ax
80101a5a:	75 0c                	jne    80101a68 <ilock+0x10b>
      panic("ilock: no type");
80101a5c:	c7 04 24 d3 85 10 80 	movl   $0x801085d3,(%esp)
80101a63:	e8 fa ea ff ff       	call   80100562 <panic>
  }
}
80101a68:	c9                   	leave  
80101a69:	c3                   	ret    

80101a6a <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101a6a:	55                   	push   %ebp
80101a6b:	89 e5                	mov    %esp,%ebp
80101a6d:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
80101a70:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101a74:	74 1c                	je     80101a92 <iunlock+0x28>
80101a76:	8b 45 08             	mov    0x8(%ebp),%eax
80101a79:	83 c0 0c             	add    $0xc,%eax
80101a7c:	89 04 24             	mov    %eax,(%esp)
80101a7f:	e8 af 34 00 00       	call   80104f33 <holdingsleep>
80101a84:	85 c0                	test   %eax,%eax
80101a86:	74 0a                	je     80101a92 <iunlock+0x28>
80101a88:	8b 45 08             	mov    0x8(%ebp),%eax
80101a8b:	8b 40 08             	mov    0x8(%eax),%eax
80101a8e:	85 c0                	test   %eax,%eax
80101a90:	7f 0c                	jg     80101a9e <iunlock+0x34>
    panic("iunlock");
80101a92:	c7 04 24 e2 85 10 80 	movl   $0x801085e2,(%esp)
80101a99:	e8 c4 ea ff ff       	call   80100562 <panic>

  releasesleep(&ip->lock);
80101a9e:	8b 45 08             	mov    0x8(%ebp),%eax
80101aa1:	83 c0 0c             	add    $0xc,%eax
80101aa4:	89 04 24             	mov    %eax,(%esp)
80101aa7:	e8 45 34 00 00       	call   80104ef1 <releasesleep>
}
80101aac:	c9                   	leave  
80101aad:	c3                   	ret    

80101aae <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101aae:	55                   	push   %ebp
80101aaf:	89 e5                	mov    %esp,%ebp
80101ab1:	83 ec 28             	sub    $0x28,%esp
  acquiresleep(&ip->lock);
80101ab4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab7:	83 c0 0c             	add    $0xc,%eax
80101aba:	89 04 24             	mov    %eax,(%esp)
80101abd:	e8 d4 33 00 00       	call   80104e96 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
80101ac2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac5:	8b 40 4c             	mov    0x4c(%eax),%eax
80101ac8:	85 c0                	test   %eax,%eax
80101aca:	74 5c                	je     80101b28 <iput+0x7a>
80101acc:	8b 45 08             	mov    0x8(%ebp),%eax
80101acf:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80101ad3:	66 85 c0             	test   %ax,%ax
80101ad6:	75 50                	jne    80101b28 <iput+0x7a>
    acquire(&icache.lock);
80101ad8:	c7 04 24 60 1a 11 80 	movl   $0x80111a60,(%esp)
80101adf:	e8 fc 34 00 00       	call   80104fe0 <acquire>
    int r = ip->ref;
80101ae4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ae7:	8b 40 08             	mov    0x8(%eax),%eax
80101aea:	89 45 f4             	mov    %eax,-0xc(%ebp)
    release(&icache.lock);
80101aed:	c7 04 24 60 1a 11 80 	movl   $0x80111a60,(%esp)
80101af4:	e8 4f 35 00 00       	call   80105048 <release>
    if(r == 1){
80101af9:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
80101afd:	75 29                	jne    80101b28 <iput+0x7a>
      // inode has no links and no other references: truncate and free.
      itrunc(ip);
80101aff:	8b 45 08             	mov    0x8(%ebp),%eax
80101b02:	89 04 24             	mov    %eax,(%esp)
80101b05:	e8 86 01 00 00       	call   80101c90 <itrunc>
      ip->type = 0;
80101b0a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b0d:	66 c7 40 50 00 00    	movw   $0x0,0x50(%eax)
      iupdate(ip);
80101b13:	8b 45 08             	mov    0x8(%ebp),%eax
80101b16:	89 04 24             	mov    %eax,(%esp)
80101b19:	e8 7a fc ff ff       	call   80101798 <iupdate>
      ip->valid = 0;
80101b1e:	8b 45 08             	mov    0x8(%ebp),%eax
80101b21:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
    }
  }
  releasesleep(&ip->lock);
80101b28:	8b 45 08             	mov    0x8(%ebp),%eax
80101b2b:	83 c0 0c             	add    $0xc,%eax
80101b2e:	89 04 24             	mov    %eax,(%esp)
80101b31:	e8 bb 33 00 00       	call   80104ef1 <releasesleep>

  acquire(&icache.lock);
80101b36:	c7 04 24 60 1a 11 80 	movl   $0x80111a60,(%esp)
80101b3d:	e8 9e 34 00 00       	call   80104fe0 <acquire>
  ip->ref--;
80101b42:	8b 45 08             	mov    0x8(%ebp),%eax
80101b45:	8b 40 08             	mov    0x8(%eax),%eax
80101b48:	8d 50 ff             	lea    -0x1(%eax),%edx
80101b4b:	8b 45 08             	mov    0x8(%ebp),%eax
80101b4e:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101b51:	c7 04 24 60 1a 11 80 	movl   $0x80111a60,(%esp)
80101b58:	e8 eb 34 00 00       	call   80105048 <release>
}
80101b5d:	c9                   	leave  
80101b5e:	c3                   	ret    

80101b5f <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101b5f:	55                   	push   %ebp
80101b60:	89 e5                	mov    %esp,%ebp
80101b62:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101b65:	8b 45 08             	mov    0x8(%ebp),%eax
80101b68:	89 04 24             	mov    %eax,(%esp)
80101b6b:	e8 fa fe ff ff       	call   80101a6a <iunlock>
  iput(ip);
80101b70:	8b 45 08             	mov    0x8(%ebp),%eax
80101b73:	89 04 24             	mov    %eax,(%esp)
80101b76:	e8 33 ff ff ff       	call   80101aae <iput>
}
80101b7b:	c9                   	leave  
80101b7c:	c3                   	ret    

80101b7d <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101b7d:	55                   	push   %ebp
80101b7e:	89 e5                	mov    %esp,%ebp
80101b80:	53                   	push   %ebx
80101b81:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101b84:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101b88:	77 3e                	ja     80101bc8 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101b8a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b8d:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b90:	83 c2 14             	add    $0x14,%edx
80101b93:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b97:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b9a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b9e:	75 20                	jne    80101bc0 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101ba0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ba3:	8b 00                	mov    (%eax),%eax
80101ba5:	89 04 24             	mov    %eax,(%esp)
80101ba8:	e8 3a f8 ff ff       	call   801013e7 <balloc>
80101bad:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bb0:	8b 45 08             	mov    0x8(%ebp),%eax
80101bb3:	8b 55 0c             	mov    0xc(%ebp),%edx
80101bb6:	8d 4a 14             	lea    0x14(%edx),%ecx
80101bb9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bbc:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101bc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bc3:	e9 c2 00 00 00       	jmp    80101c8a <bmap+0x10d>
  }
  bn -= NDIRECT;
80101bc8:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101bcc:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101bd0:	0f 87 a8 00 00 00    	ja     80101c7e <bmap+0x101>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101bd6:	8b 45 08             	mov    0x8(%ebp),%eax
80101bd9:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101bdf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101be2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101be6:	75 1c                	jne    80101c04 <bmap+0x87>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101be8:	8b 45 08             	mov    0x8(%ebp),%eax
80101beb:	8b 00                	mov    (%eax),%eax
80101bed:	89 04 24             	mov    %eax,(%esp)
80101bf0:	e8 f2 f7 ff ff       	call   801013e7 <balloc>
80101bf5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bf8:	8b 45 08             	mov    0x8(%ebp),%eax
80101bfb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bfe:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
    bp = bread(ip->dev, addr);
80101c04:	8b 45 08             	mov    0x8(%ebp),%eax
80101c07:	8b 00                	mov    (%eax),%eax
80101c09:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c0c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c10:	89 04 24             	mov    %eax,(%esp)
80101c13:	e8 9d e5 ff ff       	call   801001b5 <bread>
80101c18:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101c1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c1e:	83 c0 5c             	add    $0x5c,%eax
80101c21:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101c24:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c27:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101c2e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101c31:	01 d0                	add    %edx,%eax
80101c33:	8b 00                	mov    (%eax),%eax
80101c35:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c38:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c3c:	75 30                	jne    80101c6e <bmap+0xf1>
      a[bn] = addr = balloc(ip->dev);
80101c3e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c41:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101c48:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101c4b:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101c4e:	8b 45 08             	mov    0x8(%ebp),%eax
80101c51:	8b 00                	mov    (%eax),%eax
80101c53:	89 04 24             	mov    %eax,(%esp)
80101c56:	e8 8c f7 ff ff       	call   801013e7 <balloc>
80101c5b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c61:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101c63:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c66:	89 04 24             	mov    %eax,(%esp)
80101c69:	e8 24 1a 00 00       	call   80103692 <log_write>
    }
    brelse(bp);
80101c6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c71:	89 04 24             	mov    %eax,(%esp)
80101c74:	e8 b3 e5 ff ff       	call   8010022c <brelse>
    return addr;
80101c79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c7c:	eb 0c                	jmp    80101c8a <bmap+0x10d>
  }

  panic("bmap: out of range");
80101c7e:	c7 04 24 ea 85 10 80 	movl   $0x801085ea,(%esp)
80101c85:	e8 d8 e8 ff ff       	call   80100562 <panic>
}
80101c8a:	83 c4 24             	add    $0x24,%esp
80101c8d:	5b                   	pop    %ebx
80101c8e:	5d                   	pop    %ebp
80101c8f:	c3                   	ret    

80101c90 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101c90:	55                   	push   %ebp
80101c91:	89 e5                	mov    %esp,%ebp
80101c93:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c96:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101c9d:	eb 44                	jmp    80101ce3 <itrunc+0x53>
    if(ip->addrs[i]){
80101c9f:	8b 45 08             	mov    0x8(%ebp),%eax
80101ca2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ca5:	83 c2 14             	add    $0x14,%edx
80101ca8:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101cac:	85 c0                	test   %eax,%eax
80101cae:	74 2f                	je     80101cdf <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101cb0:	8b 45 08             	mov    0x8(%ebp),%eax
80101cb3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cb6:	83 c2 14             	add    $0x14,%edx
80101cb9:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101cbd:	8b 45 08             	mov    0x8(%ebp),%eax
80101cc0:	8b 00                	mov    (%eax),%eax
80101cc2:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cc6:	89 04 24             	mov    %eax,(%esp)
80101cc9:	e8 57 f8 ff ff       	call   80101525 <bfree>
      ip->addrs[i] = 0;
80101cce:	8b 45 08             	mov    0x8(%ebp),%eax
80101cd1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cd4:	83 c2 14             	add    $0x14,%edx
80101cd7:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101cde:	00 
  for(i = 0; i < NDIRECT; i++){
80101cdf:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101ce3:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101ce7:	7e b6                	jle    80101c9f <itrunc+0xf>
    }
  }

  if(ip->addrs[NDIRECT]){
80101ce9:	8b 45 08             	mov    0x8(%ebp),%eax
80101cec:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101cf2:	85 c0                	test   %eax,%eax
80101cf4:	0f 84 a4 00 00 00    	je     80101d9e <itrunc+0x10e>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101cfa:	8b 45 08             	mov    0x8(%ebp),%eax
80101cfd:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
80101d03:	8b 45 08             	mov    0x8(%ebp),%eax
80101d06:	8b 00                	mov    (%eax),%eax
80101d08:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d0c:	89 04 24             	mov    %eax,(%esp)
80101d0f:	e8 a1 e4 ff ff       	call   801001b5 <bread>
80101d14:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101d17:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d1a:	83 c0 5c             	add    $0x5c,%eax
80101d1d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101d20:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101d27:	eb 3b                	jmp    80101d64 <itrunc+0xd4>
      if(a[j])
80101d29:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d2c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d33:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101d36:	01 d0                	add    %edx,%eax
80101d38:	8b 00                	mov    (%eax),%eax
80101d3a:	85 c0                	test   %eax,%eax
80101d3c:	74 22                	je     80101d60 <itrunc+0xd0>
        bfree(ip->dev, a[j]);
80101d3e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d41:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d48:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101d4b:	01 d0                	add    %edx,%eax
80101d4d:	8b 10                	mov    (%eax),%edx
80101d4f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d52:	8b 00                	mov    (%eax),%eax
80101d54:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d58:	89 04 24             	mov    %eax,(%esp)
80101d5b:	e8 c5 f7 ff ff       	call   80101525 <bfree>
    for(j = 0; j < NINDIRECT; j++){
80101d60:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101d64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d67:	83 f8 7f             	cmp    $0x7f,%eax
80101d6a:	76 bd                	jbe    80101d29 <itrunc+0x99>
    }
    brelse(bp);
80101d6c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d6f:	89 04 24             	mov    %eax,(%esp)
80101d72:	e8 b5 e4 ff ff       	call   8010022c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101d77:	8b 45 08             	mov    0x8(%ebp),%eax
80101d7a:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
80101d80:	8b 45 08             	mov    0x8(%ebp),%eax
80101d83:	8b 00                	mov    (%eax),%eax
80101d85:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d89:	89 04 24             	mov    %eax,(%esp)
80101d8c:	e8 94 f7 ff ff       	call   80101525 <bfree>
    ip->addrs[NDIRECT] = 0;
80101d91:	8b 45 08             	mov    0x8(%ebp),%eax
80101d94:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80101d9b:	00 00 00 
  }

  ip->size = 0;
80101d9e:	8b 45 08             	mov    0x8(%ebp),%eax
80101da1:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)
  iupdate(ip);
80101da8:	8b 45 08             	mov    0x8(%ebp),%eax
80101dab:	89 04 24             	mov    %eax,(%esp)
80101dae:	e8 e5 f9 ff ff       	call   80101798 <iupdate>
}
80101db3:	c9                   	leave  
80101db4:	c3                   	ret    

80101db5 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
80101db5:	55                   	push   %ebp
80101db6:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101db8:	8b 45 08             	mov    0x8(%ebp),%eax
80101dbb:	8b 00                	mov    (%eax),%eax
80101dbd:	89 c2                	mov    %eax,%edx
80101dbf:	8b 45 0c             	mov    0xc(%ebp),%eax
80101dc2:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101dc5:	8b 45 08             	mov    0x8(%ebp),%eax
80101dc8:	8b 50 04             	mov    0x4(%eax),%edx
80101dcb:	8b 45 0c             	mov    0xc(%ebp),%eax
80101dce:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101dd1:	8b 45 08             	mov    0x8(%ebp),%eax
80101dd4:	0f b7 50 50          	movzwl 0x50(%eax),%edx
80101dd8:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ddb:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101dde:	8b 45 08             	mov    0x8(%ebp),%eax
80101de1:	0f b7 50 56          	movzwl 0x56(%eax),%edx
80101de5:	8b 45 0c             	mov    0xc(%ebp),%eax
80101de8:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101dec:	8b 45 08             	mov    0x8(%ebp),%eax
80101def:	8b 50 58             	mov    0x58(%eax),%edx
80101df2:	8b 45 0c             	mov    0xc(%ebp),%eax
80101df5:	89 50 10             	mov    %edx,0x10(%eax)
}
80101df8:	5d                   	pop    %ebp
80101df9:	c3                   	ret    

80101dfa <readi>:
//PAGEBREAK!
// Read data from inode.
// Caller must hold ip->lock.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101dfa:	55                   	push   %ebp
80101dfb:	89 e5                	mov    %esp,%ebp
80101dfd:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101e00:	8b 45 08             	mov    0x8(%ebp),%eax
80101e03:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80101e07:	66 83 f8 03          	cmp    $0x3,%ax
80101e0b:	75 60                	jne    80101e6d <readi+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101e0d:	8b 45 08             	mov    0x8(%ebp),%eax
80101e10:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101e14:	66 85 c0             	test   %ax,%ax
80101e17:	78 20                	js     80101e39 <readi+0x3f>
80101e19:	8b 45 08             	mov    0x8(%ebp),%eax
80101e1c:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101e20:	66 83 f8 09          	cmp    $0x9,%ax
80101e24:	7f 13                	jg     80101e39 <readi+0x3f>
80101e26:	8b 45 08             	mov    0x8(%ebp),%eax
80101e29:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101e2d:	98                   	cwtl   
80101e2e:	8b 04 c5 e0 19 11 80 	mov    -0x7feee620(,%eax,8),%eax
80101e35:	85 c0                	test   %eax,%eax
80101e37:	75 0a                	jne    80101e43 <readi+0x49>
      return -1;
80101e39:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101e3e:	e9 19 01 00 00       	jmp    80101f5c <readi+0x162>
    return devsw[ip->major].read(ip, dst, n);
80101e43:	8b 45 08             	mov    0x8(%ebp),%eax
80101e46:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101e4a:	98                   	cwtl   
80101e4b:	8b 04 c5 e0 19 11 80 	mov    -0x7feee620(,%eax,8),%eax
80101e52:	8b 55 14             	mov    0x14(%ebp),%edx
80101e55:	89 54 24 08          	mov    %edx,0x8(%esp)
80101e59:	8b 55 0c             	mov    0xc(%ebp),%edx
80101e5c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e60:	8b 55 08             	mov    0x8(%ebp),%edx
80101e63:	89 14 24             	mov    %edx,(%esp)
80101e66:	ff d0                	call   *%eax
80101e68:	e9 ef 00 00 00       	jmp    80101f5c <readi+0x162>
  }

  if(off > ip->size || off + n < off)
80101e6d:	8b 45 08             	mov    0x8(%ebp),%eax
80101e70:	8b 40 58             	mov    0x58(%eax),%eax
80101e73:	3b 45 10             	cmp    0x10(%ebp),%eax
80101e76:	72 0d                	jb     80101e85 <readi+0x8b>
80101e78:	8b 45 14             	mov    0x14(%ebp),%eax
80101e7b:	8b 55 10             	mov    0x10(%ebp),%edx
80101e7e:	01 d0                	add    %edx,%eax
80101e80:	3b 45 10             	cmp    0x10(%ebp),%eax
80101e83:	73 0a                	jae    80101e8f <readi+0x95>
    return -1;
80101e85:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101e8a:	e9 cd 00 00 00       	jmp    80101f5c <readi+0x162>
  if(off + n > ip->size)
80101e8f:	8b 45 14             	mov    0x14(%ebp),%eax
80101e92:	8b 55 10             	mov    0x10(%ebp),%edx
80101e95:	01 c2                	add    %eax,%edx
80101e97:	8b 45 08             	mov    0x8(%ebp),%eax
80101e9a:	8b 40 58             	mov    0x58(%eax),%eax
80101e9d:	39 c2                	cmp    %eax,%edx
80101e9f:	76 0c                	jbe    80101ead <readi+0xb3>
    n = ip->size - off;
80101ea1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ea4:	8b 40 58             	mov    0x58(%eax),%eax
80101ea7:	2b 45 10             	sub    0x10(%ebp),%eax
80101eaa:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101ead:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101eb4:	e9 94 00 00 00       	jmp    80101f4d <readi+0x153>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101eb9:	8b 45 10             	mov    0x10(%ebp),%eax
80101ebc:	c1 e8 09             	shr    $0x9,%eax
80101ebf:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ec3:	8b 45 08             	mov    0x8(%ebp),%eax
80101ec6:	89 04 24             	mov    %eax,(%esp)
80101ec9:	e8 af fc ff ff       	call   80101b7d <bmap>
80101ece:	8b 55 08             	mov    0x8(%ebp),%edx
80101ed1:	8b 12                	mov    (%edx),%edx
80101ed3:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ed7:	89 14 24             	mov    %edx,(%esp)
80101eda:	e8 d6 e2 ff ff       	call   801001b5 <bread>
80101edf:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101ee2:	8b 45 10             	mov    0x10(%ebp),%eax
80101ee5:	25 ff 01 00 00       	and    $0x1ff,%eax
80101eea:	89 c2                	mov    %eax,%edx
80101eec:	b8 00 02 00 00       	mov    $0x200,%eax
80101ef1:	29 d0                	sub    %edx,%eax
80101ef3:	89 c2                	mov    %eax,%edx
80101ef5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ef8:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101efb:	29 c1                	sub    %eax,%ecx
80101efd:	89 c8                	mov    %ecx,%eax
80101eff:	39 c2                	cmp    %eax,%edx
80101f01:	0f 46 c2             	cmovbe %edx,%eax
80101f04:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101f07:	8b 45 10             	mov    0x10(%ebp),%eax
80101f0a:	25 ff 01 00 00       	and    $0x1ff,%eax
80101f0f:	8d 50 50             	lea    0x50(%eax),%edx
80101f12:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f15:	01 d0                	add    %edx,%eax
80101f17:	8d 50 0c             	lea    0xc(%eax),%edx
80101f1a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f1d:	89 44 24 08          	mov    %eax,0x8(%esp)
80101f21:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f25:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f28:	89 04 24             	mov    %eax,(%esp)
80101f2b:	e8 f1 33 00 00       	call   80105321 <memmove>
    brelse(bp);
80101f30:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f33:	89 04 24             	mov    %eax,(%esp)
80101f36:	e8 f1 e2 ff ff       	call   8010022c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101f3b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f3e:	01 45 f4             	add    %eax,-0xc(%ebp)
80101f41:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f44:	01 45 10             	add    %eax,0x10(%ebp)
80101f47:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f4a:	01 45 0c             	add    %eax,0xc(%ebp)
80101f4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f50:	3b 45 14             	cmp    0x14(%ebp),%eax
80101f53:	0f 82 60 ff ff ff    	jb     80101eb9 <readi+0xbf>
  }
  return n;
80101f59:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101f5c:	c9                   	leave  
80101f5d:	c3                   	ret    

80101f5e <writei>:
// PAGEBREAK!
// Write data to inode.
// Caller must hold ip->lock.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101f5e:	55                   	push   %ebp
80101f5f:	89 e5                	mov    %esp,%ebp
80101f61:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101f64:	8b 45 08             	mov    0x8(%ebp),%eax
80101f67:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80101f6b:	66 83 f8 03          	cmp    $0x3,%ax
80101f6f:	75 60                	jne    80101fd1 <writei+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101f71:	8b 45 08             	mov    0x8(%ebp),%eax
80101f74:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101f78:	66 85 c0             	test   %ax,%ax
80101f7b:	78 20                	js     80101f9d <writei+0x3f>
80101f7d:	8b 45 08             	mov    0x8(%ebp),%eax
80101f80:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101f84:	66 83 f8 09          	cmp    $0x9,%ax
80101f88:	7f 13                	jg     80101f9d <writei+0x3f>
80101f8a:	8b 45 08             	mov    0x8(%ebp),%eax
80101f8d:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101f91:	98                   	cwtl   
80101f92:	8b 04 c5 e4 19 11 80 	mov    -0x7feee61c(,%eax,8),%eax
80101f99:	85 c0                	test   %eax,%eax
80101f9b:	75 0a                	jne    80101fa7 <writei+0x49>
      return -1;
80101f9d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101fa2:	e9 44 01 00 00       	jmp    801020eb <writei+0x18d>
    return devsw[ip->major].write(ip, src, n);
80101fa7:	8b 45 08             	mov    0x8(%ebp),%eax
80101faa:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101fae:	98                   	cwtl   
80101faf:	8b 04 c5 e4 19 11 80 	mov    -0x7feee61c(,%eax,8),%eax
80101fb6:	8b 55 14             	mov    0x14(%ebp),%edx
80101fb9:	89 54 24 08          	mov    %edx,0x8(%esp)
80101fbd:	8b 55 0c             	mov    0xc(%ebp),%edx
80101fc0:	89 54 24 04          	mov    %edx,0x4(%esp)
80101fc4:	8b 55 08             	mov    0x8(%ebp),%edx
80101fc7:	89 14 24             	mov    %edx,(%esp)
80101fca:	ff d0                	call   *%eax
80101fcc:	e9 1a 01 00 00       	jmp    801020eb <writei+0x18d>
  }

  if(off > ip->size || off + n < off)
80101fd1:	8b 45 08             	mov    0x8(%ebp),%eax
80101fd4:	8b 40 58             	mov    0x58(%eax),%eax
80101fd7:	3b 45 10             	cmp    0x10(%ebp),%eax
80101fda:	72 0d                	jb     80101fe9 <writei+0x8b>
80101fdc:	8b 45 14             	mov    0x14(%ebp),%eax
80101fdf:	8b 55 10             	mov    0x10(%ebp),%edx
80101fe2:	01 d0                	add    %edx,%eax
80101fe4:	3b 45 10             	cmp    0x10(%ebp),%eax
80101fe7:	73 0a                	jae    80101ff3 <writei+0x95>
    return -1;
80101fe9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101fee:	e9 f8 00 00 00       	jmp    801020eb <writei+0x18d>
  if(off + n > MAXFILE*BSIZE)
80101ff3:	8b 45 14             	mov    0x14(%ebp),%eax
80101ff6:	8b 55 10             	mov    0x10(%ebp),%edx
80101ff9:	01 d0                	add    %edx,%eax
80101ffb:	3d 00 18 01 00       	cmp    $0x11800,%eax
80102000:	76 0a                	jbe    8010200c <writei+0xae>
    return -1;
80102002:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102007:	e9 df 00 00 00       	jmp    801020eb <writei+0x18d>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010200c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102013:	e9 9f 00 00 00       	jmp    801020b7 <writei+0x159>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102018:	8b 45 10             	mov    0x10(%ebp),%eax
8010201b:	c1 e8 09             	shr    $0x9,%eax
8010201e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102022:	8b 45 08             	mov    0x8(%ebp),%eax
80102025:	89 04 24             	mov    %eax,(%esp)
80102028:	e8 50 fb ff ff       	call   80101b7d <bmap>
8010202d:	8b 55 08             	mov    0x8(%ebp),%edx
80102030:	8b 12                	mov    (%edx),%edx
80102032:	89 44 24 04          	mov    %eax,0x4(%esp)
80102036:	89 14 24             	mov    %edx,(%esp)
80102039:	e8 77 e1 ff ff       	call   801001b5 <bread>
8010203e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102041:	8b 45 10             	mov    0x10(%ebp),%eax
80102044:	25 ff 01 00 00       	and    $0x1ff,%eax
80102049:	89 c2                	mov    %eax,%edx
8010204b:	b8 00 02 00 00       	mov    $0x200,%eax
80102050:	29 d0                	sub    %edx,%eax
80102052:	89 c2                	mov    %eax,%edx
80102054:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102057:	8b 4d 14             	mov    0x14(%ebp),%ecx
8010205a:	29 c1                	sub    %eax,%ecx
8010205c:	89 c8                	mov    %ecx,%eax
8010205e:	39 c2                	cmp    %eax,%edx
80102060:	0f 46 c2             	cmovbe %edx,%eax
80102063:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102066:	8b 45 10             	mov    0x10(%ebp),%eax
80102069:	25 ff 01 00 00       	and    $0x1ff,%eax
8010206e:	8d 50 50             	lea    0x50(%eax),%edx
80102071:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102074:	01 d0                	add    %edx,%eax
80102076:	8d 50 0c             	lea    0xc(%eax),%edx
80102079:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010207c:	89 44 24 08          	mov    %eax,0x8(%esp)
80102080:	8b 45 0c             	mov    0xc(%ebp),%eax
80102083:	89 44 24 04          	mov    %eax,0x4(%esp)
80102087:	89 14 24             	mov    %edx,(%esp)
8010208a:	e8 92 32 00 00       	call   80105321 <memmove>
    log_write(bp);
8010208f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102092:	89 04 24             	mov    %eax,(%esp)
80102095:	e8 f8 15 00 00       	call   80103692 <log_write>
    brelse(bp);
8010209a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010209d:	89 04 24             	mov    %eax,(%esp)
801020a0:	e8 87 e1 ff ff       	call   8010022c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801020a5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020a8:	01 45 f4             	add    %eax,-0xc(%ebp)
801020ab:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020ae:	01 45 10             	add    %eax,0x10(%ebp)
801020b1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020b4:	01 45 0c             	add    %eax,0xc(%ebp)
801020b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020ba:	3b 45 14             	cmp    0x14(%ebp),%eax
801020bd:	0f 82 55 ff ff ff    	jb     80102018 <writei+0xba>
  }

  if(n > 0 && off > ip->size){
801020c3:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801020c7:	74 1f                	je     801020e8 <writei+0x18a>
801020c9:	8b 45 08             	mov    0x8(%ebp),%eax
801020cc:	8b 40 58             	mov    0x58(%eax),%eax
801020cf:	3b 45 10             	cmp    0x10(%ebp),%eax
801020d2:	73 14                	jae    801020e8 <writei+0x18a>
    ip->size = off;
801020d4:	8b 45 08             	mov    0x8(%ebp),%eax
801020d7:	8b 55 10             	mov    0x10(%ebp),%edx
801020da:	89 50 58             	mov    %edx,0x58(%eax)
    iupdate(ip);
801020dd:	8b 45 08             	mov    0x8(%ebp),%eax
801020e0:	89 04 24             	mov    %eax,(%esp)
801020e3:	e8 b0 f6 ff ff       	call   80101798 <iupdate>
  }
  return n;
801020e8:	8b 45 14             	mov    0x14(%ebp),%eax
}
801020eb:	c9                   	leave  
801020ec:	c3                   	ret    

801020ed <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
801020ed:	55                   	push   %ebp
801020ee:	89 e5                	mov    %esp,%ebp
801020f0:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
801020f3:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801020fa:	00 
801020fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801020fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80102102:	8b 45 08             	mov    0x8(%ebp),%eax
80102105:	89 04 24             	mov    %eax,(%esp)
80102108:	e8 b7 32 00 00       	call   801053c4 <strncmp>
}
8010210d:	c9                   	leave  
8010210e:	c3                   	ret    

8010210f <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
8010210f:	55                   	push   %ebp
80102110:	89 e5                	mov    %esp,%ebp
80102112:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102115:	8b 45 08             	mov    0x8(%ebp),%eax
80102118:	0f b7 40 50          	movzwl 0x50(%eax),%eax
8010211c:	66 83 f8 01          	cmp    $0x1,%ax
80102120:	74 0c                	je     8010212e <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102122:	c7 04 24 fd 85 10 80 	movl   $0x801085fd,(%esp)
80102129:	e8 34 e4 ff ff       	call   80100562 <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
8010212e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102135:	e9 88 00 00 00       	jmp    801021c2 <dirlookup+0xb3>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010213a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102141:	00 
80102142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102145:	89 44 24 08          	mov    %eax,0x8(%esp)
80102149:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010214c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102150:	8b 45 08             	mov    0x8(%ebp),%eax
80102153:	89 04 24             	mov    %eax,(%esp)
80102156:	e8 9f fc ff ff       	call   80101dfa <readi>
8010215b:	83 f8 10             	cmp    $0x10,%eax
8010215e:	74 0c                	je     8010216c <dirlookup+0x5d>
      panic("dirlookup read");
80102160:	c7 04 24 0f 86 10 80 	movl   $0x8010860f,(%esp)
80102167:	e8 f6 e3 ff ff       	call   80100562 <panic>
    if(de.inum == 0)
8010216c:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102170:	66 85 c0             	test   %ax,%ax
80102173:	75 02                	jne    80102177 <dirlookup+0x68>
      continue;
80102175:	eb 47                	jmp    801021be <dirlookup+0xaf>
    if(namecmp(name, de.name) == 0){
80102177:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010217a:	83 c0 02             	add    $0x2,%eax
8010217d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102181:	8b 45 0c             	mov    0xc(%ebp),%eax
80102184:	89 04 24             	mov    %eax,(%esp)
80102187:	e8 61 ff ff ff       	call   801020ed <namecmp>
8010218c:	85 c0                	test   %eax,%eax
8010218e:	75 2e                	jne    801021be <dirlookup+0xaf>
      // entry matches path element
      if(poff)
80102190:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102194:	74 08                	je     8010219e <dirlookup+0x8f>
        *poff = off;
80102196:	8b 45 10             	mov    0x10(%ebp),%eax
80102199:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010219c:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
8010219e:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801021a2:	0f b7 c0             	movzwl %ax,%eax
801021a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
801021a8:	8b 45 08             	mov    0x8(%ebp),%eax
801021ab:	8b 00                	mov    (%eax),%eax
801021ad:	8b 55 f0             	mov    -0x10(%ebp),%edx
801021b0:	89 54 24 04          	mov    %edx,0x4(%esp)
801021b4:	89 04 24             	mov    %eax,(%esp)
801021b7:	e8 9a f6 ff ff       	call   80101856 <iget>
801021bc:	eb 18                	jmp    801021d6 <dirlookup+0xc7>
  for(off = 0; off < dp->size; off += sizeof(de)){
801021be:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801021c2:	8b 45 08             	mov    0x8(%ebp),%eax
801021c5:	8b 40 58             	mov    0x58(%eax),%eax
801021c8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801021cb:	0f 87 69 ff ff ff    	ja     8010213a <dirlookup+0x2b>
    }
  }

  return 0;
801021d1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801021d6:	c9                   	leave  
801021d7:	c3                   	ret    

801021d8 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
801021d8:	55                   	push   %ebp
801021d9:	89 e5                	mov    %esp,%ebp
801021db:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
801021de:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801021e5:	00 
801021e6:	8b 45 0c             	mov    0xc(%ebp),%eax
801021e9:	89 44 24 04          	mov    %eax,0x4(%esp)
801021ed:	8b 45 08             	mov    0x8(%ebp),%eax
801021f0:	89 04 24             	mov    %eax,(%esp)
801021f3:	e8 17 ff ff ff       	call   8010210f <dirlookup>
801021f8:	89 45 f0             	mov    %eax,-0x10(%ebp)
801021fb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801021ff:	74 15                	je     80102216 <dirlink+0x3e>
    iput(ip);
80102201:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102204:	89 04 24             	mov    %eax,(%esp)
80102207:	e8 a2 f8 ff ff       	call   80101aae <iput>
    return -1;
8010220c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102211:	e9 b7 00 00 00       	jmp    801022cd <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102216:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010221d:	eb 46                	jmp    80102265 <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010221f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102222:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102229:	00 
8010222a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010222e:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102231:	89 44 24 04          	mov    %eax,0x4(%esp)
80102235:	8b 45 08             	mov    0x8(%ebp),%eax
80102238:	89 04 24             	mov    %eax,(%esp)
8010223b:	e8 ba fb ff ff       	call   80101dfa <readi>
80102240:	83 f8 10             	cmp    $0x10,%eax
80102243:	74 0c                	je     80102251 <dirlink+0x79>
      panic("dirlink read");
80102245:	c7 04 24 1e 86 10 80 	movl   $0x8010861e,(%esp)
8010224c:	e8 11 e3 ff ff       	call   80100562 <panic>
    if(de.inum == 0)
80102251:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102255:	66 85 c0             	test   %ax,%ax
80102258:	75 02                	jne    8010225c <dirlink+0x84>
      break;
8010225a:	eb 16                	jmp    80102272 <dirlink+0x9a>
  for(off = 0; off < dp->size; off += sizeof(de)){
8010225c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010225f:	83 c0 10             	add    $0x10,%eax
80102262:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102265:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102268:	8b 45 08             	mov    0x8(%ebp),%eax
8010226b:	8b 40 58             	mov    0x58(%eax),%eax
8010226e:	39 c2                	cmp    %eax,%edx
80102270:	72 ad                	jb     8010221f <dirlink+0x47>
  }

  strncpy(de.name, name, DIRSIZ);
80102272:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102279:	00 
8010227a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010227d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102281:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102284:	83 c0 02             	add    $0x2,%eax
80102287:	89 04 24             	mov    %eax,(%esp)
8010228a:	e8 8b 31 00 00       	call   8010541a <strncpy>
  de.inum = inum;
8010228f:	8b 45 10             	mov    0x10(%ebp),%eax
80102292:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102296:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102299:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801022a0:	00 
801022a1:	89 44 24 08          	mov    %eax,0x8(%esp)
801022a5:	8d 45 e0             	lea    -0x20(%ebp),%eax
801022a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801022ac:	8b 45 08             	mov    0x8(%ebp),%eax
801022af:	89 04 24             	mov    %eax,(%esp)
801022b2:	e8 a7 fc ff ff       	call   80101f5e <writei>
801022b7:	83 f8 10             	cmp    $0x10,%eax
801022ba:	74 0c                	je     801022c8 <dirlink+0xf0>
    panic("dirlink");
801022bc:	c7 04 24 2b 86 10 80 	movl   $0x8010862b,(%esp)
801022c3:	e8 9a e2 ff ff       	call   80100562 <panic>

  return 0;
801022c8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801022cd:	c9                   	leave  
801022ce:	c3                   	ret    

801022cf <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
801022cf:	55                   	push   %ebp
801022d0:	89 e5                	mov    %esp,%ebp
801022d2:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
801022d5:	eb 04                	jmp    801022db <skipelem+0xc>
    path++;
801022d7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
801022db:	8b 45 08             	mov    0x8(%ebp),%eax
801022de:	0f b6 00             	movzbl (%eax),%eax
801022e1:	3c 2f                	cmp    $0x2f,%al
801022e3:	74 f2                	je     801022d7 <skipelem+0x8>
  if(*path == 0)
801022e5:	8b 45 08             	mov    0x8(%ebp),%eax
801022e8:	0f b6 00             	movzbl (%eax),%eax
801022eb:	84 c0                	test   %al,%al
801022ed:	75 0a                	jne    801022f9 <skipelem+0x2a>
    return 0;
801022ef:	b8 00 00 00 00       	mov    $0x0,%eax
801022f4:	e9 86 00 00 00       	jmp    8010237f <skipelem+0xb0>
  s = path;
801022f9:	8b 45 08             	mov    0x8(%ebp),%eax
801022fc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
801022ff:	eb 04                	jmp    80102305 <skipelem+0x36>
    path++;
80102301:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path != '/' && *path != 0)
80102305:	8b 45 08             	mov    0x8(%ebp),%eax
80102308:	0f b6 00             	movzbl (%eax),%eax
8010230b:	3c 2f                	cmp    $0x2f,%al
8010230d:	74 0a                	je     80102319 <skipelem+0x4a>
8010230f:	8b 45 08             	mov    0x8(%ebp),%eax
80102312:	0f b6 00             	movzbl (%eax),%eax
80102315:	84 c0                	test   %al,%al
80102317:	75 e8                	jne    80102301 <skipelem+0x32>
  len = path - s;
80102319:	8b 55 08             	mov    0x8(%ebp),%edx
8010231c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010231f:	29 c2                	sub    %eax,%edx
80102321:	89 d0                	mov    %edx,%eax
80102323:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102326:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
8010232a:	7e 1c                	jle    80102348 <skipelem+0x79>
    memmove(name, s, DIRSIZ);
8010232c:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102333:	00 
80102334:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102337:	89 44 24 04          	mov    %eax,0x4(%esp)
8010233b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010233e:	89 04 24             	mov    %eax,(%esp)
80102341:	e8 db 2f 00 00       	call   80105321 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102346:	eb 2a                	jmp    80102372 <skipelem+0xa3>
    memmove(name, s, len);
80102348:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010234b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010234f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102352:	89 44 24 04          	mov    %eax,0x4(%esp)
80102356:	8b 45 0c             	mov    0xc(%ebp),%eax
80102359:	89 04 24             	mov    %eax,(%esp)
8010235c:	e8 c0 2f 00 00       	call   80105321 <memmove>
    name[len] = 0;
80102361:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102364:	8b 45 0c             	mov    0xc(%ebp),%eax
80102367:	01 d0                	add    %edx,%eax
80102369:	c6 00 00             	movb   $0x0,(%eax)
  while(*path == '/')
8010236c:	eb 04                	jmp    80102372 <skipelem+0xa3>
    path++;
8010236e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
80102372:	8b 45 08             	mov    0x8(%ebp),%eax
80102375:	0f b6 00             	movzbl (%eax),%eax
80102378:	3c 2f                	cmp    $0x2f,%al
8010237a:	74 f2                	je     8010236e <skipelem+0x9f>
  return path;
8010237c:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010237f:	c9                   	leave  
80102380:	c3                   	ret    

80102381 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80102381:	55                   	push   %ebp
80102382:	89 e5                	mov    %esp,%ebp
80102384:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102387:	8b 45 08             	mov    0x8(%ebp),%eax
8010238a:	0f b6 00             	movzbl (%eax),%eax
8010238d:	3c 2f                	cmp    $0x2f,%al
8010238f:	75 1c                	jne    801023ad <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
80102391:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102398:	00 
80102399:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801023a0:	e8 b1 f4 ff ff       	call   80101856 <iget>
801023a5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(myproc()->cwd);

  while((path = skipelem(path, name)) != 0){
801023a8:	e9 ae 00 00 00       	jmp    8010245b <namex+0xda>
    ip = idup(myproc()->cwd);
801023ad:	e8 af 1d 00 00       	call   80104161 <myproc>
801023b2:	8b 40 68             	mov    0x68(%eax),%eax
801023b5:	89 04 24             	mov    %eax,(%esp)
801023b8:	e8 6e f5 ff ff       	call   8010192b <idup>
801023bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while((path = skipelem(path, name)) != 0){
801023c0:	e9 96 00 00 00       	jmp    8010245b <namex+0xda>
    ilock(ip);
801023c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023c8:	89 04 24             	mov    %eax,(%esp)
801023cb:	e8 8d f5 ff ff       	call   8010195d <ilock>
    if(ip->type != T_DIR){
801023d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023d3:	0f b7 40 50          	movzwl 0x50(%eax),%eax
801023d7:	66 83 f8 01          	cmp    $0x1,%ax
801023db:	74 15                	je     801023f2 <namex+0x71>
      iunlockput(ip);
801023dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023e0:	89 04 24             	mov    %eax,(%esp)
801023e3:	e8 77 f7 ff ff       	call   80101b5f <iunlockput>
      return 0;
801023e8:	b8 00 00 00 00       	mov    $0x0,%eax
801023ed:	e9 a3 00 00 00       	jmp    80102495 <namex+0x114>
    }
    if(nameiparent && *path == '\0'){
801023f2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801023f6:	74 1d                	je     80102415 <namex+0x94>
801023f8:	8b 45 08             	mov    0x8(%ebp),%eax
801023fb:	0f b6 00             	movzbl (%eax),%eax
801023fe:	84 c0                	test   %al,%al
80102400:	75 13                	jne    80102415 <namex+0x94>
      // Stop one level early.
      iunlock(ip);
80102402:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102405:	89 04 24             	mov    %eax,(%esp)
80102408:	e8 5d f6 ff ff       	call   80101a6a <iunlock>
      return ip;
8010240d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102410:	e9 80 00 00 00       	jmp    80102495 <namex+0x114>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102415:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010241c:	00 
8010241d:	8b 45 10             	mov    0x10(%ebp),%eax
80102420:	89 44 24 04          	mov    %eax,0x4(%esp)
80102424:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102427:	89 04 24             	mov    %eax,(%esp)
8010242a:	e8 e0 fc ff ff       	call   8010210f <dirlookup>
8010242f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102432:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102436:	75 12                	jne    8010244a <namex+0xc9>
      iunlockput(ip);
80102438:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010243b:	89 04 24             	mov    %eax,(%esp)
8010243e:	e8 1c f7 ff ff       	call   80101b5f <iunlockput>
      return 0;
80102443:	b8 00 00 00 00       	mov    $0x0,%eax
80102448:	eb 4b                	jmp    80102495 <namex+0x114>
    }
    iunlockput(ip);
8010244a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010244d:	89 04 24             	mov    %eax,(%esp)
80102450:	e8 0a f7 ff ff       	call   80101b5f <iunlockput>
    ip = next;
80102455:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102458:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while((path = skipelem(path, name)) != 0){
8010245b:	8b 45 10             	mov    0x10(%ebp),%eax
8010245e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102462:	8b 45 08             	mov    0x8(%ebp),%eax
80102465:	89 04 24             	mov    %eax,(%esp)
80102468:	e8 62 fe ff ff       	call   801022cf <skipelem>
8010246d:	89 45 08             	mov    %eax,0x8(%ebp)
80102470:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102474:	0f 85 4b ff ff ff    	jne    801023c5 <namex+0x44>
  }
  if(nameiparent){
8010247a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010247e:	74 12                	je     80102492 <namex+0x111>
    iput(ip);
80102480:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102483:	89 04 24             	mov    %eax,(%esp)
80102486:	e8 23 f6 ff ff       	call   80101aae <iput>
    return 0;
8010248b:	b8 00 00 00 00       	mov    $0x0,%eax
80102490:	eb 03                	jmp    80102495 <namex+0x114>
  }
  return ip;
80102492:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102495:	c9                   	leave  
80102496:	c3                   	ret    

80102497 <namei>:

struct inode*
namei(char *path)
{
80102497:	55                   	push   %ebp
80102498:	89 e5                	mov    %esp,%ebp
8010249a:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
8010249d:	8d 45 ea             	lea    -0x16(%ebp),%eax
801024a0:	89 44 24 08          	mov    %eax,0x8(%esp)
801024a4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801024ab:	00 
801024ac:	8b 45 08             	mov    0x8(%ebp),%eax
801024af:	89 04 24             	mov    %eax,(%esp)
801024b2:	e8 ca fe ff ff       	call   80102381 <namex>
}
801024b7:	c9                   	leave  
801024b8:	c3                   	ret    

801024b9 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
801024b9:	55                   	push   %ebp
801024ba:	89 e5                	mov    %esp,%ebp
801024bc:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
801024bf:	8b 45 0c             	mov    0xc(%ebp),%eax
801024c2:	89 44 24 08          	mov    %eax,0x8(%esp)
801024c6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801024cd:	00 
801024ce:	8b 45 08             	mov    0x8(%ebp),%eax
801024d1:	89 04 24             	mov    %eax,(%esp)
801024d4:	e8 a8 fe ff ff       	call   80102381 <namex>
}
801024d9:	c9                   	leave  
801024da:	c3                   	ret    

801024db <inb>:
{
801024db:	55                   	push   %ebp
801024dc:	89 e5                	mov    %esp,%ebp
801024de:	83 ec 14             	sub    $0x14,%esp
801024e1:	8b 45 08             	mov    0x8(%ebp),%eax
801024e4:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801024e8:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801024ec:	89 c2                	mov    %eax,%edx
801024ee:	ec                   	in     (%dx),%al
801024ef:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801024f2:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801024f6:	c9                   	leave  
801024f7:	c3                   	ret    

801024f8 <insl>:
{
801024f8:	55                   	push   %ebp
801024f9:	89 e5                	mov    %esp,%ebp
801024fb:	57                   	push   %edi
801024fc:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
801024fd:	8b 55 08             	mov    0x8(%ebp),%edx
80102500:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102503:	8b 45 10             	mov    0x10(%ebp),%eax
80102506:	89 cb                	mov    %ecx,%ebx
80102508:	89 df                	mov    %ebx,%edi
8010250a:	89 c1                	mov    %eax,%ecx
8010250c:	fc                   	cld    
8010250d:	f3 6d                	rep insl (%dx),%es:(%edi)
8010250f:	89 c8                	mov    %ecx,%eax
80102511:	89 fb                	mov    %edi,%ebx
80102513:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102516:	89 45 10             	mov    %eax,0x10(%ebp)
}
80102519:	5b                   	pop    %ebx
8010251a:	5f                   	pop    %edi
8010251b:	5d                   	pop    %ebp
8010251c:	c3                   	ret    

8010251d <outb>:
{
8010251d:	55                   	push   %ebp
8010251e:	89 e5                	mov    %esp,%ebp
80102520:	83 ec 08             	sub    $0x8,%esp
80102523:	8b 55 08             	mov    0x8(%ebp),%edx
80102526:	8b 45 0c             	mov    0xc(%ebp),%eax
80102529:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010252d:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102530:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102534:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102538:	ee                   	out    %al,(%dx)
}
80102539:	c9                   	leave  
8010253a:	c3                   	ret    

8010253b <outsl>:
{
8010253b:	55                   	push   %ebp
8010253c:	89 e5                	mov    %esp,%ebp
8010253e:	56                   	push   %esi
8010253f:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102540:	8b 55 08             	mov    0x8(%ebp),%edx
80102543:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102546:	8b 45 10             	mov    0x10(%ebp),%eax
80102549:	89 cb                	mov    %ecx,%ebx
8010254b:	89 de                	mov    %ebx,%esi
8010254d:	89 c1                	mov    %eax,%ecx
8010254f:	fc                   	cld    
80102550:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102552:	89 c8                	mov    %ecx,%eax
80102554:	89 f3                	mov    %esi,%ebx
80102556:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102559:	89 45 10             	mov    %eax,0x10(%ebp)
}
8010255c:	5b                   	pop    %ebx
8010255d:	5e                   	pop    %esi
8010255e:	5d                   	pop    %ebp
8010255f:	c3                   	ret    

80102560 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102560:	55                   	push   %ebp
80102561:	89 e5                	mov    %esp,%ebp
80102563:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80102566:	90                   	nop
80102567:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010256e:	e8 68 ff ff ff       	call   801024db <inb>
80102573:	0f b6 c0             	movzbl %al,%eax
80102576:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102579:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010257c:	25 c0 00 00 00       	and    $0xc0,%eax
80102581:	83 f8 40             	cmp    $0x40,%eax
80102584:	75 e1                	jne    80102567 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102586:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010258a:	74 11                	je     8010259d <idewait+0x3d>
8010258c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010258f:	83 e0 21             	and    $0x21,%eax
80102592:	85 c0                	test   %eax,%eax
80102594:	74 07                	je     8010259d <idewait+0x3d>
    return -1;
80102596:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010259b:	eb 05                	jmp    801025a2 <idewait+0x42>
  return 0;
8010259d:	b8 00 00 00 00       	mov    $0x0,%eax
}
801025a2:	c9                   	leave  
801025a3:	c3                   	ret    

801025a4 <ideinit>:

void
ideinit(void)
{
801025a4:	55                   	push   %ebp
801025a5:	89 e5                	mov    %esp,%ebp
801025a7:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
801025aa:	c7 44 24 04 33 86 10 	movl   $0x80108633,0x4(%esp)
801025b1:	80 
801025b2:	c7 04 24 e0 b5 10 80 	movl   $0x8010b5e0,(%esp)
801025b9:	e8 01 2a 00 00       	call   80104fbf <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
801025be:	a1 80 3d 11 80       	mov    0x80113d80,%eax
801025c3:	83 e8 01             	sub    $0x1,%eax
801025c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801025ca:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801025d1:	e8 69 04 00 00       	call   80102a3f <ioapicenable>
  idewait(0);
801025d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801025dd:	e8 7e ff ff ff       	call   80102560 <idewait>

  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
801025e2:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
801025e9:	00 
801025ea:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801025f1:	e8 27 ff ff ff       	call   8010251d <outb>
  for(i=0; i<1000; i++){
801025f6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801025fd:	eb 20                	jmp    8010261f <ideinit+0x7b>
    if(inb(0x1f7) != 0){
801025ff:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102606:	e8 d0 fe ff ff       	call   801024db <inb>
8010260b:	84 c0                	test   %al,%al
8010260d:	74 0c                	je     8010261b <ideinit+0x77>
      havedisk1 = 1;
8010260f:	c7 05 18 b6 10 80 01 	movl   $0x1,0x8010b618
80102616:	00 00 00 
      break;
80102619:	eb 0d                	jmp    80102628 <ideinit+0x84>
  for(i=0; i<1000; i++){
8010261b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010261f:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102626:	7e d7                	jle    801025ff <ideinit+0x5b>
    }
  }

  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102628:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
8010262f:	00 
80102630:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102637:	e8 e1 fe ff ff       	call   8010251d <outb>
}
8010263c:	c9                   	leave  
8010263d:	c3                   	ret    

8010263e <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
8010263e:	55                   	push   %ebp
8010263f:	89 e5                	mov    %esp,%ebp
80102641:	83 ec 28             	sub    $0x28,%esp
  if(b == 0)
80102644:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102648:	75 0c                	jne    80102656 <idestart+0x18>
    panic("idestart");
8010264a:	c7 04 24 37 86 10 80 	movl   $0x80108637,(%esp)
80102651:	e8 0c df ff ff       	call   80100562 <panic>
  if(b->blockno >= FSSIZE)
80102656:	8b 45 08             	mov    0x8(%ebp),%eax
80102659:	8b 40 08             	mov    0x8(%eax),%eax
8010265c:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80102661:	76 0c                	jbe    8010266f <idestart+0x31>
    panic("incorrect blockno");
80102663:	c7 04 24 40 86 10 80 	movl   $0x80108640,(%esp)
8010266a:	e8 f3 de ff ff       	call   80100562 <panic>
  int sector_per_block =  BSIZE/SECTOR_SIZE;
8010266f:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  int sector = b->blockno * sector_per_block;
80102676:	8b 45 08             	mov    0x8(%ebp),%eax
80102679:	8b 50 08             	mov    0x8(%eax),%edx
8010267c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010267f:	0f af c2             	imul   %edx,%eax
80102682:	89 45 f0             	mov    %eax,-0x10(%ebp)
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
80102685:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
80102689:	75 07                	jne    80102692 <idestart+0x54>
8010268b:	b8 20 00 00 00       	mov    $0x20,%eax
80102690:	eb 05                	jmp    80102697 <idestart+0x59>
80102692:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102697:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;
8010269a:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
8010269e:	75 07                	jne    801026a7 <idestart+0x69>
801026a0:	b8 30 00 00 00       	mov    $0x30,%eax
801026a5:	eb 05                	jmp    801026ac <idestart+0x6e>
801026a7:	b8 c5 00 00 00       	mov    $0xc5,%eax
801026ac:	89 45 e8             	mov    %eax,-0x18(%ebp)

  if (sector_per_block > 7) panic("idestart");
801026af:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
801026b3:	7e 0c                	jle    801026c1 <idestart+0x83>
801026b5:	c7 04 24 37 86 10 80 	movl   $0x80108637,(%esp)
801026bc:	e8 a1 de ff ff       	call   80100562 <panic>

  idewait(0);
801026c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801026c8:	e8 93 fe ff ff       	call   80102560 <idewait>
  outb(0x3f6, 0);  // generate interrupt
801026cd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801026d4:	00 
801026d5:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
801026dc:	e8 3c fe ff ff       	call   8010251d <outb>
  outb(0x1f2, sector_per_block);  // number of sectors
801026e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801026e4:	0f b6 c0             	movzbl %al,%eax
801026e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801026eb:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
801026f2:	e8 26 fe ff ff       	call   8010251d <outb>
  outb(0x1f3, sector & 0xff);
801026f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801026fa:	0f b6 c0             	movzbl %al,%eax
801026fd:	89 44 24 04          	mov    %eax,0x4(%esp)
80102701:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102708:	e8 10 fe ff ff       	call   8010251d <outb>
  outb(0x1f4, (sector >> 8) & 0xff);
8010270d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102710:	c1 f8 08             	sar    $0x8,%eax
80102713:	0f b6 c0             	movzbl %al,%eax
80102716:	89 44 24 04          	mov    %eax,0x4(%esp)
8010271a:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102721:	e8 f7 fd ff ff       	call   8010251d <outb>
  outb(0x1f5, (sector >> 16) & 0xff);
80102726:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102729:	c1 f8 10             	sar    $0x10,%eax
8010272c:	0f b6 c0             	movzbl %al,%eax
8010272f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102733:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
8010273a:	e8 de fd ff ff       	call   8010251d <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
8010273f:	8b 45 08             	mov    0x8(%ebp),%eax
80102742:	8b 40 04             	mov    0x4(%eax),%eax
80102745:	83 e0 01             	and    $0x1,%eax
80102748:	c1 e0 04             	shl    $0x4,%eax
8010274b:	89 c2                	mov    %eax,%edx
8010274d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102750:	c1 f8 18             	sar    $0x18,%eax
80102753:	83 e0 0f             	and    $0xf,%eax
80102756:	09 d0                	or     %edx,%eax
80102758:	83 c8 e0             	or     $0xffffffe0,%eax
8010275b:	0f b6 c0             	movzbl %al,%eax
8010275e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102762:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102769:	e8 af fd ff ff       	call   8010251d <outb>
  if(b->flags & B_DIRTY){
8010276e:	8b 45 08             	mov    0x8(%ebp),%eax
80102771:	8b 00                	mov    (%eax),%eax
80102773:	83 e0 04             	and    $0x4,%eax
80102776:	85 c0                	test   %eax,%eax
80102778:	74 36                	je     801027b0 <idestart+0x172>
    outb(0x1f7, write_cmd);
8010277a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010277d:	0f b6 c0             	movzbl %al,%eax
80102780:	89 44 24 04          	mov    %eax,0x4(%esp)
80102784:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010278b:	e8 8d fd ff ff       	call   8010251d <outb>
    outsl(0x1f0, b->data, BSIZE/4);
80102790:	8b 45 08             	mov    0x8(%ebp),%eax
80102793:	83 c0 5c             	add    $0x5c,%eax
80102796:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010279d:	00 
8010279e:	89 44 24 04          	mov    %eax,0x4(%esp)
801027a2:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801027a9:	e8 8d fd ff ff       	call   8010253b <outsl>
801027ae:	eb 16                	jmp    801027c6 <idestart+0x188>
  } else {
    outb(0x1f7, read_cmd);
801027b0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801027b3:	0f b6 c0             	movzbl %al,%eax
801027b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801027ba:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801027c1:	e8 57 fd ff ff       	call   8010251d <outb>
  }
}
801027c6:	c9                   	leave  
801027c7:	c3                   	ret    

801027c8 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801027c8:	55                   	push   %ebp
801027c9:	89 e5                	mov    %esp,%ebp
801027cb:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801027ce:	c7 04 24 e0 b5 10 80 	movl   $0x8010b5e0,(%esp)
801027d5:	e8 06 28 00 00       	call   80104fe0 <acquire>

  if((b = idequeue) == 0){
801027da:	a1 14 b6 10 80       	mov    0x8010b614,%eax
801027df:	89 45 f4             	mov    %eax,-0xc(%ebp)
801027e2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801027e6:	75 11                	jne    801027f9 <ideintr+0x31>
    release(&idelock);
801027e8:	c7 04 24 e0 b5 10 80 	movl   $0x8010b5e0,(%esp)
801027ef:	e8 54 28 00 00       	call   80105048 <release>
    return;
801027f4:	e9 90 00 00 00       	jmp    80102889 <ideintr+0xc1>
  }
  idequeue = b->qnext;
801027f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027fc:	8b 40 58             	mov    0x58(%eax),%eax
801027ff:	a3 14 b6 10 80       	mov    %eax,0x8010b614

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102804:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102807:	8b 00                	mov    (%eax),%eax
80102809:	83 e0 04             	and    $0x4,%eax
8010280c:	85 c0                	test   %eax,%eax
8010280e:	75 2e                	jne    8010283e <ideintr+0x76>
80102810:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102817:	e8 44 fd ff ff       	call   80102560 <idewait>
8010281c:	85 c0                	test   %eax,%eax
8010281e:	78 1e                	js     8010283e <ideintr+0x76>
    insl(0x1f0, b->data, BSIZE/4);
80102820:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102823:	83 c0 5c             	add    $0x5c,%eax
80102826:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010282d:	00 
8010282e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102832:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102839:	e8 ba fc ff ff       	call   801024f8 <insl>

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
8010283e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102841:	8b 00                	mov    (%eax),%eax
80102843:	83 c8 02             	or     $0x2,%eax
80102846:	89 c2                	mov    %eax,%edx
80102848:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010284b:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
8010284d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102850:	8b 00                	mov    (%eax),%eax
80102852:	83 e0 fb             	and    $0xfffffffb,%eax
80102855:	89 c2                	mov    %eax,%edx
80102857:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010285a:	89 10                	mov    %edx,(%eax)
  wakeup(b);
8010285c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010285f:	89 04 24             	mov    %eax,(%esp)
80102862:	e8 69 22 00 00       	call   80104ad0 <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80102867:	a1 14 b6 10 80       	mov    0x8010b614,%eax
8010286c:	85 c0                	test   %eax,%eax
8010286e:	74 0d                	je     8010287d <ideintr+0xb5>
    idestart(idequeue);
80102870:	a1 14 b6 10 80       	mov    0x8010b614,%eax
80102875:	89 04 24             	mov    %eax,(%esp)
80102878:	e8 c1 fd ff ff       	call   8010263e <idestart>

  release(&idelock);
8010287d:	c7 04 24 e0 b5 10 80 	movl   $0x8010b5e0,(%esp)
80102884:	e8 bf 27 00 00       	call   80105048 <release>
}
80102889:	c9                   	leave  
8010288a:	c3                   	ret    

8010288b <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
8010288b:	55                   	push   %ebp
8010288c:	89 e5                	mov    %esp,%ebp
8010288e:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80102891:	8b 45 08             	mov    0x8(%ebp),%eax
80102894:	83 c0 0c             	add    $0xc,%eax
80102897:	89 04 24             	mov    %eax,(%esp)
8010289a:	e8 94 26 00 00       	call   80104f33 <holdingsleep>
8010289f:	85 c0                	test   %eax,%eax
801028a1:	75 0c                	jne    801028af <iderw+0x24>
    panic("iderw: buf not locked");
801028a3:	c7 04 24 52 86 10 80 	movl   $0x80108652,(%esp)
801028aa:	e8 b3 dc ff ff       	call   80100562 <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801028af:	8b 45 08             	mov    0x8(%ebp),%eax
801028b2:	8b 00                	mov    (%eax),%eax
801028b4:	83 e0 06             	and    $0x6,%eax
801028b7:	83 f8 02             	cmp    $0x2,%eax
801028ba:	75 0c                	jne    801028c8 <iderw+0x3d>
    panic("iderw: nothing to do");
801028bc:	c7 04 24 68 86 10 80 	movl   $0x80108668,(%esp)
801028c3:	e8 9a dc ff ff       	call   80100562 <panic>
  if(b->dev != 0 && !havedisk1)
801028c8:	8b 45 08             	mov    0x8(%ebp),%eax
801028cb:	8b 40 04             	mov    0x4(%eax),%eax
801028ce:	85 c0                	test   %eax,%eax
801028d0:	74 15                	je     801028e7 <iderw+0x5c>
801028d2:	a1 18 b6 10 80       	mov    0x8010b618,%eax
801028d7:	85 c0                	test   %eax,%eax
801028d9:	75 0c                	jne    801028e7 <iderw+0x5c>
    panic("iderw: ide disk 1 not present");
801028db:	c7 04 24 7d 86 10 80 	movl   $0x8010867d,(%esp)
801028e2:	e8 7b dc ff ff       	call   80100562 <panic>

  acquire(&idelock);  //DOC:acquire-lock
801028e7:	c7 04 24 e0 b5 10 80 	movl   $0x8010b5e0,(%esp)
801028ee:	e8 ed 26 00 00       	call   80104fe0 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
801028f3:	8b 45 08             	mov    0x8(%ebp),%eax
801028f6:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
801028fd:	c7 45 f4 14 b6 10 80 	movl   $0x8010b614,-0xc(%ebp)
80102904:	eb 0b                	jmp    80102911 <iderw+0x86>
80102906:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102909:	8b 00                	mov    (%eax),%eax
8010290b:	83 c0 58             	add    $0x58,%eax
8010290e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102911:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102914:	8b 00                	mov    (%eax),%eax
80102916:	85 c0                	test   %eax,%eax
80102918:	75 ec                	jne    80102906 <iderw+0x7b>
    ;
  *pp = b;
8010291a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010291d:	8b 55 08             	mov    0x8(%ebp),%edx
80102920:	89 10                	mov    %edx,(%eax)

  // Start disk if necessary.
  if(idequeue == b)
80102922:	a1 14 b6 10 80       	mov    0x8010b614,%eax
80102927:	3b 45 08             	cmp    0x8(%ebp),%eax
8010292a:	75 0d                	jne    80102939 <iderw+0xae>
    idestart(b);
8010292c:	8b 45 08             	mov    0x8(%ebp),%eax
8010292f:	89 04 24             	mov    %eax,(%esp)
80102932:	e8 07 fd ff ff       	call   8010263e <idestart>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102937:	eb 15                	jmp    8010294e <iderw+0xc3>
80102939:	eb 13                	jmp    8010294e <iderw+0xc3>
    sleep(b, &idelock);
8010293b:	c7 44 24 04 e0 b5 10 	movl   $0x8010b5e0,0x4(%esp)
80102942:	80 
80102943:	8b 45 08             	mov    0x8(%ebp),%eax
80102946:	89 04 24             	mov    %eax,(%esp)
80102949:	e8 ab 20 00 00       	call   801049f9 <sleep>
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
8010294e:	8b 45 08             	mov    0x8(%ebp),%eax
80102951:	8b 00                	mov    (%eax),%eax
80102953:	83 e0 06             	and    $0x6,%eax
80102956:	83 f8 02             	cmp    $0x2,%eax
80102959:	75 e0                	jne    8010293b <iderw+0xb0>
  }


  release(&idelock);
8010295b:	c7 04 24 e0 b5 10 80 	movl   $0x8010b5e0,(%esp)
80102962:	e8 e1 26 00 00       	call   80105048 <release>
}
80102967:	c9                   	leave  
80102968:	c3                   	ret    

80102969 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102969:	55                   	push   %ebp
8010296a:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
8010296c:	a1 b4 36 11 80       	mov    0x801136b4,%eax
80102971:	8b 55 08             	mov    0x8(%ebp),%edx
80102974:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102976:	a1 b4 36 11 80       	mov    0x801136b4,%eax
8010297b:	8b 40 10             	mov    0x10(%eax),%eax
}
8010297e:	5d                   	pop    %ebp
8010297f:	c3                   	ret    

80102980 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102980:	55                   	push   %ebp
80102981:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102983:	a1 b4 36 11 80       	mov    0x801136b4,%eax
80102988:	8b 55 08             	mov    0x8(%ebp),%edx
8010298b:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
8010298d:	a1 b4 36 11 80       	mov    0x801136b4,%eax
80102992:	8b 55 0c             	mov    0xc(%ebp),%edx
80102995:	89 50 10             	mov    %edx,0x10(%eax)
}
80102998:	5d                   	pop    %ebp
80102999:	c3                   	ret    

8010299a <ioapicinit>:

void
ioapicinit(void)
{
8010299a:	55                   	push   %ebp
8010299b:	89 e5                	mov    %esp,%ebp
8010299d:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
801029a0:	c7 05 b4 36 11 80 00 	movl   $0xfec00000,0x801136b4
801029a7:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
801029aa:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801029b1:	e8 b3 ff ff ff       	call   80102969 <ioapicread>
801029b6:	c1 e8 10             	shr    $0x10,%eax
801029b9:	25 ff 00 00 00       	and    $0xff,%eax
801029be:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
801029c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801029c8:	e8 9c ff ff ff       	call   80102969 <ioapicread>
801029cd:	c1 e8 18             	shr    $0x18,%eax
801029d0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
801029d3:	0f b6 05 e0 37 11 80 	movzbl 0x801137e0,%eax
801029da:	0f b6 c0             	movzbl %al,%eax
801029dd:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801029e0:	74 0c                	je     801029ee <ioapicinit+0x54>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
801029e2:	c7 04 24 9c 86 10 80 	movl   $0x8010869c,(%esp)
801029e9:	e8 da d9 ff ff       	call   801003c8 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
801029ee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801029f5:	eb 3e                	jmp    80102a35 <ioapicinit+0x9b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
801029f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029fa:	83 c0 20             	add    $0x20,%eax
801029fd:	0d 00 00 01 00       	or     $0x10000,%eax
80102a02:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a05:	83 c2 08             	add    $0x8,%edx
80102a08:	01 d2                	add    %edx,%edx
80102a0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a0e:	89 14 24             	mov    %edx,(%esp)
80102a11:	e8 6a ff ff ff       	call   80102980 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102a16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a19:	83 c0 08             	add    $0x8,%eax
80102a1c:	01 c0                	add    %eax,%eax
80102a1e:	83 c0 01             	add    $0x1,%eax
80102a21:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102a28:	00 
80102a29:	89 04 24             	mov    %eax,(%esp)
80102a2c:	e8 4f ff ff ff       	call   80102980 <ioapicwrite>
  for(i = 0; i <= maxintr; i++){
80102a31:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102a35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a38:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102a3b:	7e ba                	jle    801029f7 <ioapicinit+0x5d>
  }
}
80102a3d:	c9                   	leave  
80102a3e:	c3                   	ret    

80102a3f <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102a3f:	55                   	push   %ebp
80102a40:	89 e5                	mov    %esp,%ebp
80102a42:	83 ec 08             	sub    $0x8,%esp
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102a45:	8b 45 08             	mov    0x8(%ebp),%eax
80102a48:	83 c0 20             	add    $0x20,%eax
80102a4b:	8b 55 08             	mov    0x8(%ebp),%edx
80102a4e:	83 c2 08             	add    $0x8,%edx
80102a51:	01 d2                	add    %edx,%edx
80102a53:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a57:	89 14 24             	mov    %edx,(%esp)
80102a5a:	e8 21 ff ff ff       	call   80102980 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102a5f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a62:	c1 e0 18             	shl    $0x18,%eax
80102a65:	8b 55 08             	mov    0x8(%ebp),%edx
80102a68:	83 c2 08             	add    $0x8,%edx
80102a6b:	01 d2                	add    %edx,%edx
80102a6d:	83 c2 01             	add    $0x1,%edx
80102a70:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a74:	89 14 24             	mov    %edx,(%esp)
80102a77:	e8 04 ff ff ff       	call   80102980 <ioapicwrite>
}
80102a7c:	c9                   	leave  
80102a7d:	c3                   	ret    

80102a7e <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102a7e:	55                   	push   %ebp
80102a7f:	89 e5                	mov    %esp,%ebp
80102a81:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102a84:	c7 44 24 04 ce 86 10 	movl   $0x801086ce,0x4(%esp)
80102a8b:	80 
80102a8c:	c7 04 24 c0 36 11 80 	movl   $0x801136c0,(%esp)
80102a93:	e8 27 25 00 00       	call   80104fbf <initlock>
  kmem.use_lock = 0;
80102a98:	c7 05 f4 36 11 80 00 	movl   $0x0,0x801136f4
80102a9f:	00 00 00 
  freerange(vstart, vend);
80102aa2:	8b 45 0c             	mov    0xc(%ebp),%eax
80102aa5:	89 44 24 04          	mov    %eax,0x4(%esp)
80102aa9:	8b 45 08             	mov    0x8(%ebp),%eax
80102aac:	89 04 24             	mov    %eax,(%esp)
80102aaf:	e8 26 00 00 00       	call   80102ada <freerange>
}
80102ab4:	c9                   	leave  
80102ab5:	c3                   	ret    

80102ab6 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102ab6:	55                   	push   %ebp
80102ab7:	89 e5                	mov    %esp,%ebp
80102ab9:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102abc:	8b 45 0c             	mov    0xc(%ebp),%eax
80102abf:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ac3:	8b 45 08             	mov    0x8(%ebp),%eax
80102ac6:	89 04 24             	mov    %eax,(%esp)
80102ac9:	e8 0c 00 00 00       	call   80102ada <freerange>
  kmem.use_lock = 1;
80102ace:	c7 05 f4 36 11 80 01 	movl   $0x1,0x801136f4
80102ad5:	00 00 00 
}
80102ad8:	c9                   	leave  
80102ad9:	c3                   	ret    

80102ada <freerange>:

void
freerange(void *vstart, void *vend)
{
80102ada:	55                   	push   %ebp
80102adb:	89 e5                	mov    %esp,%ebp
80102add:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102ae0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ae3:	05 ff 0f 00 00       	add    $0xfff,%eax
80102ae8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102aed:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102af0:	eb 12                	jmp    80102b04 <freerange+0x2a>
    kfree(p);
80102af2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102af5:	89 04 24             	mov    %eax,(%esp)
80102af8:	e8 16 00 00 00       	call   80102b13 <kfree>
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102afd:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102b04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b07:	05 00 10 00 00       	add    $0x1000,%eax
80102b0c:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102b0f:	76 e1                	jbe    80102af2 <freerange+0x18>
}
80102b11:	c9                   	leave  
80102b12:	c3                   	ret    

80102b13 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102b13:	55                   	push   %ebp
80102b14:	89 e5                	mov    %esp,%ebp
80102b16:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80102b19:	8b 45 08             	mov    0x8(%ebp),%eax
80102b1c:	25 ff 0f 00 00       	and    $0xfff,%eax
80102b21:	85 c0                	test   %eax,%eax
80102b23:	75 18                	jne    80102b3d <kfree+0x2a>
80102b25:	81 7d 08 28 67 11 80 	cmpl   $0x80116728,0x8(%ebp)
80102b2c:	72 0f                	jb     80102b3d <kfree+0x2a>
80102b2e:	8b 45 08             	mov    0x8(%ebp),%eax
80102b31:	05 00 00 00 80       	add    $0x80000000,%eax
80102b36:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102b3b:	76 0c                	jbe    80102b49 <kfree+0x36>
    panic("kfree");
80102b3d:	c7 04 24 d3 86 10 80 	movl   $0x801086d3,(%esp)
80102b44:	e8 19 da ff ff       	call   80100562 <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102b49:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102b50:	00 
80102b51:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102b58:	00 
80102b59:	8b 45 08             	mov    0x8(%ebp),%eax
80102b5c:	89 04 24             	mov    %eax,(%esp)
80102b5f:	e8 ee 26 00 00       	call   80105252 <memset>

  if(kmem.use_lock)
80102b64:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102b69:	85 c0                	test   %eax,%eax
80102b6b:	74 0c                	je     80102b79 <kfree+0x66>
    acquire(&kmem.lock);
80102b6d:	c7 04 24 c0 36 11 80 	movl   $0x801136c0,(%esp)
80102b74:	e8 67 24 00 00       	call   80104fe0 <acquire>
  r = (struct run*)v;
80102b79:	8b 45 08             	mov    0x8(%ebp),%eax
80102b7c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102b7f:	8b 15 f8 36 11 80    	mov    0x801136f8,%edx
80102b85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b88:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102b8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b8d:	a3 f8 36 11 80       	mov    %eax,0x801136f8
  if(kmem.use_lock)
80102b92:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102b97:	85 c0                	test   %eax,%eax
80102b99:	74 0c                	je     80102ba7 <kfree+0x94>
    release(&kmem.lock);
80102b9b:	c7 04 24 c0 36 11 80 	movl   $0x801136c0,(%esp)
80102ba2:	e8 a1 24 00 00       	call   80105048 <release>
}
80102ba7:	c9                   	leave  
80102ba8:	c3                   	ret    

80102ba9 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102ba9:	55                   	push   %ebp
80102baa:	89 e5                	mov    %esp,%ebp
80102bac:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102baf:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102bb4:	85 c0                	test   %eax,%eax
80102bb6:	74 0c                	je     80102bc4 <kalloc+0x1b>
    acquire(&kmem.lock);
80102bb8:	c7 04 24 c0 36 11 80 	movl   $0x801136c0,(%esp)
80102bbf:	e8 1c 24 00 00       	call   80104fe0 <acquire>
  r = kmem.freelist;
80102bc4:	a1 f8 36 11 80       	mov    0x801136f8,%eax
80102bc9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102bcc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102bd0:	74 0a                	je     80102bdc <kalloc+0x33>
    kmem.freelist = r->next;
80102bd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bd5:	8b 00                	mov    (%eax),%eax
80102bd7:	a3 f8 36 11 80       	mov    %eax,0x801136f8
  if(kmem.use_lock)
80102bdc:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102be1:	85 c0                	test   %eax,%eax
80102be3:	74 0c                	je     80102bf1 <kalloc+0x48>
    release(&kmem.lock);
80102be5:	c7 04 24 c0 36 11 80 	movl   $0x801136c0,(%esp)
80102bec:	e8 57 24 00 00       	call   80105048 <release>
  return (char*)r;
80102bf1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102bf4:	c9                   	leave  
80102bf5:	c3                   	ret    

80102bf6 <inb>:
{
80102bf6:	55                   	push   %ebp
80102bf7:	89 e5                	mov    %esp,%ebp
80102bf9:	83 ec 14             	sub    $0x14,%esp
80102bfc:	8b 45 08             	mov    0x8(%ebp),%eax
80102bff:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102c03:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102c07:	89 c2                	mov    %eax,%edx
80102c09:	ec                   	in     (%dx),%al
80102c0a:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102c0d:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102c11:	c9                   	leave  
80102c12:	c3                   	ret    

80102c13 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102c13:	55                   	push   %ebp
80102c14:	89 e5                	mov    %esp,%ebp
80102c16:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102c19:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102c20:	e8 d1 ff ff ff       	call   80102bf6 <inb>
80102c25:	0f b6 c0             	movzbl %al,%eax
80102c28:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102c2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c2e:	83 e0 01             	and    $0x1,%eax
80102c31:	85 c0                	test   %eax,%eax
80102c33:	75 0a                	jne    80102c3f <kbdgetc+0x2c>
    return -1;
80102c35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102c3a:	e9 25 01 00 00       	jmp    80102d64 <kbdgetc+0x151>
  data = inb(KBDATAP);
80102c3f:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102c46:	e8 ab ff ff ff       	call   80102bf6 <inb>
80102c4b:	0f b6 c0             	movzbl %al,%eax
80102c4e:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102c51:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102c58:	75 17                	jne    80102c71 <kbdgetc+0x5e>
    shift |= E0ESC;
80102c5a:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102c5f:	83 c8 40             	or     $0x40,%eax
80102c62:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
    return 0;
80102c67:	b8 00 00 00 00       	mov    $0x0,%eax
80102c6c:	e9 f3 00 00 00       	jmp    80102d64 <kbdgetc+0x151>
  } else if(data & 0x80){
80102c71:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c74:	25 80 00 00 00       	and    $0x80,%eax
80102c79:	85 c0                	test   %eax,%eax
80102c7b:	74 45                	je     80102cc2 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102c7d:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102c82:	83 e0 40             	and    $0x40,%eax
80102c85:	85 c0                	test   %eax,%eax
80102c87:	75 08                	jne    80102c91 <kbdgetc+0x7e>
80102c89:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c8c:	83 e0 7f             	and    $0x7f,%eax
80102c8f:	eb 03                	jmp    80102c94 <kbdgetc+0x81>
80102c91:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c94:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102c97:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c9a:	05 20 90 10 80       	add    $0x80109020,%eax
80102c9f:	0f b6 00             	movzbl (%eax),%eax
80102ca2:	83 c8 40             	or     $0x40,%eax
80102ca5:	0f b6 c0             	movzbl %al,%eax
80102ca8:	f7 d0                	not    %eax
80102caa:	89 c2                	mov    %eax,%edx
80102cac:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102cb1:	21 d0                	and    %edx,%eax
80102cb3:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
    return 0;
80102cb8:	b8 00 00 00 00       	mov    $0x0,%eax
80102cbd:	e9 a2 00 00 00       	jmp    80102d64 <kbdgetc+0x151>
  } else if(shift & E0ESC){
80102cc2:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102cc7:	83 e0 40             	and    $0x40,%eax
80102cca:	85 c0                	test   %eax,%eax
80102ccc:	74 14                	je     80102ce2 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102cce:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102cd5:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102cda:	83 e0 bf             	and    $0xffffffbf,%eax
80102cdd:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
  }

  shift |= shiftcode[data];
80102ce2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102ce5:	05 20 90 10 80       	add    $0x80109020,%eax
80102cea:	0f b6 00             	movzbl (%eax),%eax
80102ced:	0f b6 d0             	movzbl %al,%edx
80102cf0:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102cf5:	09 d0                	or     %edx,%eax
80102cf7:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
  shift ^= togglecode[data];
80102cfc:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102cff:	05 20 91 10 80       	add    $0x80109120,%eax
80102d04:	0f b6 00             	movzbl (%eax),%eax
80102d07:	0f b6 d0             	movzbl %al,%edx
80102d0a:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102d0f:	31 d0                	xor    %edx,%eax
80102d11:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
  c = charcode[shift & (CTL | SHIFT)][data];
80102d16:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102d1b:	83 e0 03             	and    $0x3,%eax
80102d1e:	8b 14 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%edx
80102d25:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d28:	01 d0                	add    %edx,%eax
80102d2a:	0f b6 00             	movzbl (%eax),%eax
80102d2d:	0f b6 c0             	movzbl %al,%eax
80102d30:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102d33:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102d38:	83 e0 08             	and    $0x8,%eax
80102d3b:	85 c0                	test   %eax,%eax
80102d3d:	74 22                	je     80102d61 <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80102d3f:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102d43:	76 0c                	jbe    80102d51 <kbdgetc+0x13e>
80102d45:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102d49:	77 06                	ja     80102d51 <kbdgetc+0x13e>
      c += 'A' - 'a';
80102d4b:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102d4f:	eb 10                	jmp    80102d61 <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80102d51:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102d55:	76 0a                	jbe    80102d61 <kbdgetc+0x14e>
80102d57:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102d5b:	77 04                	ja     80102d61 <kbdgetc+0x14e>
      c += 'a' - 'A';
80102d5d:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102d61:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102d64:	c9                   	leave  
80102d65:	c3                   	ret    

80102d66 <kbdintr>:

void
kbdintr(void)
{
80102d66:	55                   	push   %ebp
80102d67:	89 e5                	mov    %esp,%ebp
80102d69:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102d6c:	c7 04 24 13 2c 10 80 	movl   $0x80102c13,(%esp)
80102d73:	e8 71 da ff ff       	call   801007e9 <consoleintr>
}
80102d78:	c9                   	leave  
80102d79:	c3                   	ret    

80102d7a <inb>:
{
80102d7a:	55                   	push   %ebp
80102d7b:	89 e5                	mov    %esp,%ebp
80102d7d:	83 ec 14             	sub    $0x14,%esp
80102d80:	8b 45 08             	mov    0x8(%ebp),%eax
80102d83:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102d87:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102d8b:	89 c2                	mov    %eax,%edx
80102d8d:	ec                   	in     (%dx),%al
80102d8e:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102d91:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102d95:	c9                   	leave  
80102d96:	c3                   	ret    

80102d97 <outb>:
{
80102d97:	55                   	push   %ebp
80102d98:	89 e5                	mov    %esp,%ebp
80102d9a:	83 ec 08             	sub    $0x8,%esp
80102d9d:	8b 55 08             	mov    0x8(%ebp),%edx
80102da0:	8b 45 0c             	mov    0xc(%ebp),%eax
80102da3:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102da7:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102daa:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102dae:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102db2:	ee                   	out    %al,(%dx)
}
80102db3:	c9                   	leave  
80102db4:	c3                   	ret    

80102db5 <lapicw>:
volatile uint *lapic;  // Initialized in mp.c

//PAGEBREAK!
static void
lapicw(int index, int value)
{
80102db5:	55                   	push   %ebp
80102db6:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102db8:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102dbd:	8b 55 08             	mov    0x8(%ebp),%edx
80102dc0:	c1 e2 02             	shl    $0x2,%edx
80102dc3:	01 c2                	add    %eax,%edx
80102dc5:	8b 45 0c             	mov    0xc(%ebp),%eax
80102dc8:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102dca:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102dcf:	83 c0 20             	add    $0x20,%eax
80102dd2:	8b 00                	mov    (%eax),%eax
}
80102dd4:	5d                   	pop    %ebp
80102dd5:	c3                   	ret    

80102dd6 <lapicinit>:

void
lapicinit(void)
{
80102dd6:	55                   	push   %ebp
80102dd7:	89 e5                	mov    %esp,%ebp
80102dd9:	83 ec 08             	sub    $0x8,%esp
  if(!lapic)
80102ddc:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102de1:	85 c0                	test   %eax,%eax
80102de3:	75 05                	jne    80102dea <lapicinit+0x14>
    return;
80102de5:	e9 43 01 00 00       	jmp    80102f2d <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102dea:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102df1:	00 
80102df2:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102df9:	e8 b7 ff ff ff       	call   80102db5 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102dfe:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102e05:	00 
80102e06:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102e0d:	e8 a3 ff ff ff       	call   80102db5 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102e12:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102e19:	00 
80102e1a:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102e21:	e8 8f ff ff ff       	call   80102db5 <lapicw>
  lapicw(TICR, 10000000);
80102e26:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102e2d:	00 
80102e2e:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102e35:	e8 7b ff ff ff       	call   80102db5 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102e3a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102e41:	00 
80102e42:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102e49:	e8 67 ff ff ff       	call   80102db5 <lapicw>
  lapicw(LINT1, MASKED);
80102e4e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102e55:	00 
80102e56:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102e5d:	e8 53 ff ff ff       	call   80102db5 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102e62:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102e67:	83 c0 30             	add    $0x30,%eax
80102e6a:	8b 00                	mov    (%eax),%eax
80102e6c:	c1 e8 10             	shr    $0x10,%eax
80102e6f:	0f b6 c0             	movzbl %al,%eax
80102e72:	83 f8 03             	cmp    $0x3,%eax
80102e75:	76 14                	jbe    80102e8b <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80102e77:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102e7e:	00 
80102e7f:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102e86:	e8 2a ff ff ff       	call   80102db5 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102e8b:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102e92:	00 
80102e93:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102e9a:	e8 16 ff ff ff       	call   80102db5 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102e9f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ea6:	00 
80102ea7:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102eae:	e8 02 ff ff ff       	call   80102db5 <lapicw>
  lapicw(ESR, 0);
80102eb3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102eba:	00 
80102ebb:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102ec2:	e8 ee fe ff ff       	call   80102db5 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102ec7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ece:	00 
80102ecf:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102ed6:	e8 da fe ff ff       	call   80102db5 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102edb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ee2:	00 
80102ee3:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102eea:	e8 c6 fe ff ff       	call   80102db5 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102eef:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80102ef6:	00 
80102ef7:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102efe:	e8 b2 fe ff ff       	call   80102db5 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102f03:	90                   	nop
80102f04:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102f09:	05 00 03 00 00       	add    $0x300,%eax
80102f0e:	8b 00                	mov    (%eax),%eax
80102f10:	25 00 10 00 00       	and    $0x1000,%eax
80102f15:	85 c0                	test   %eax,%eax
80102f17:	75 eb                	jne    80102f04 <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102f19:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f20:	00 
80102f21:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80102f28:	e8 88 fe ff ff       	call   80102db5 <lapicw>
}
80102f2d:	c9                   	leave  
80102f2e:	c3                   	ret    

80102f2f <lapicid>:

int
lapicid(void)
{
80102f2f:	55                   	push   %ebp
80102f30:	89 e5                	mov    %esp,%ebp
  if (!lapic)
80102f32:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102f37:	85 c0                	test   %eax,%eax
80102f39:	75 07                	jne    80102f42 <lapicid+0x13>
    return 0;
80102f3b:	b8 00 00 00 00       	mov    $0x0,%eax
80102f40:	eb 0d                	jmp    80102f4f <lapicid+0x20>
  return lapic[ID] >> 24;
80102f42:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102f47:	83 c0 20             	add    $0x20,%eax
80102f4a:	8b 00                	mov    (%eax),%eax
80102f4c:	c1 e8 18             	shr    $0x18,%eax
}
80102f4f:	5d                   	pop    %ebp
80102f50:	c3                   	ret    

80102f51 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80102f51:	55                   	push   %ebp
80102f52:	89 e5                	mov    %esp,%ebp
80102f54:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80102f57:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102f5c:	85 c0                	test   %eax,%eax
80102f5e:	74 14                	je     80102f74 <lapiceoi+0x23>
    lapicw(EOI, 0);
80102f60:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f67:	00 
80102f68:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102f6f:	e8 41 fe ff ff       	call   80102db5 <lapicw>
}
80102f74:	c9                   	leave  
80102f75:	c3                   	ret    

80102f76 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80102f76:	55                   	push   %ebp
80102f77:	89 e5                	mov    %esp,%ebp
}
80102f79:	5d                   	pop    %ebp
80102f7a:	c3                   	ret    

80102f7b <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80102f7b:	55                   	push   %ebp
80102f7c:	89 e5                	mov    %esp,%ebp
80102f7e:	83 ec 1c             	sub    $0x1c,%esp
80102f81:	8b 45 08             	mov    0x8(%ebp),%eax
80102f84:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;

  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
80102f87:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80102f8e:	00 
80102f8f:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80102f96:	e8 fc fd ff ff       	call   80102d97 <outb>
  outb(CMOS_PORT+1, 0x0A);
80102f9b:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80102fa2:	00 
80102fa3:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80102faa:	e8 e8 fd ff ff       	call   80102d97 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80102faf:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80102fb6:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102fb9:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80102fbe:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102fc1:	8d 50 02             	lea    0x2(%eax),%edx
80102fc4:	8b 45 0c             	mov    0xc(%ebp),%eax
80102fc7:	c1 e8 04             	shr    $0x4,%eax
80102fca:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80102fcd:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80102fd1:	c1 e0 18             	shl    $0x18,%eax
80102fd4:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fd8:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102fdf:	e8 d1 fd ff ff       	call   80102db5 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102fe4:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80102feb:	00 
80102fec:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102ff3:	e8 bd fd ff ff       	call   80102db5 <lapicw>
  microdelay(200);
80102ff8:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102fff:	e8 72 ff ff ff       	call   80102f76 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103004:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
8010300b:	00 
8010300c:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103013:	e8 9d fd ff ff       	call   80102db5 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103018:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010301f:	e8 52 ff ff ff       	call   80102f76 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103024:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010302b:	eb 40                	jmp    8010306d <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
8010302d:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103031:	c1 e0 18             	shl    $0x18,%eax
80103034:	89 44 24 04          	mov    %eax,0x4(%esp)
80103038:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010303f:	e8 71 fd ff ff       	call   80102db5 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103044:	8b 45 0c             	mov    0xc(%ebp),%eax
80103047:	c1 e8 0c             	shr    $0xc,%eax
8010304a:	80 cc 06             	or     $0x6,%ah
8010304d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103051:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103058:	e8 58 fd ff ff       	call   80102db5 <lapicw>
    microdelay(200);
8010305d:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103064:	e8 0d ff ff ff       	call   80102f76 <microdelay>
  for(i = 0; i < 2; i++){
80103069:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010306d:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103071:	7e ba                	jle    8010302d <lapicstartap+0xb2>
  }
}
80103073:	c9                   	leave  
80103074:	c3                   	ret    

80103075 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
80103075:	55                   	push   %ebp
80103076:	89 e5                	mov    %esp,%ebp
80103078:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
8010307b:	8b 45 08             	mov    0x8(%ebp),%eax
8010307e:	0f b6 c0             	movzbl %al,%eax
80103081:	89 44 24 04          	mov    %eax,0x4(%esp)
80103085:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010308c:	e8 06 fd ff ff       	call   80102d97 <outb>
  microdelay(200);
80103091:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103098:	e8 d9 fe ff ff       	call   80102f76 <microdelay>

  return inb(CMOS_RETURN);
8010309d:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801030a4:	e8 d1 fc ff ff       	call   80102d7a <inb>
801030a9:	0f b6 c0             	movzbl %al,%eax
}
801030ac:	c9                   	leave  
801030ad:	c3                   	ret    

801030ae <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
801030ae:	55                   	push   %ebp
801030af:	89 e5                	mov    %esp,%ebp
801030b1:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
801030b4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801030bb:	e8 b5 ff ff ff       	call   80103075 <cmos_read>
801030c0:	8b 55 08             	mov    0x8(%ebp),%edx
801030c3:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
801030c5:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801030cc:	e8 a4 ff ff ff       	call   80103075 <cmos_read>
801030d1:	8b 55 08             	mov    0x8(%ebp),%edx
801030d4:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
801030d7:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801030de:	e8 92 ff ff ff       	call   80103075 <cmos_read>
801030e3:	8b 55 08             	mov    0x8(%ebp),%edx
801030e6:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
801030e9:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
801030f0:	e8 80 ff ff ff       	call   80103075 <cmos_read>
801030f5:	8b 55 08             	mov    0x8(%ebp),%edx
801030f8:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
801030fb:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80103102:	e8 6e ff ff ff       	call   80103075 <cmos_read>
80103107:	8b 55 08             	mov    0x8(%ebp),%edx
8010310a:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
8010310d:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
80103114:	e8 5c ff ff ff       	call   80103075 <cmos_read>
80103119:	8b 55 08             	mov    0x8(%ebp),%edx
8010311c:	89 42 14             	mov    %eax,0x14(%edx)
}
8010311f:	c9                   	leave  
80103120:	c3                   	ret    

80103121 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
80103121:	55                   	push   %ebp
80103122:	89 e5                	mov    %esp,%ebp
80103124:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80103127:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
8010312e:	e8 42 ff ff ff       	call   80103075 <cmos_read>
80103133:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
80103136:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103139:	83 e0 04             	and    $0x4,%eax
8010313c:	85 c0                	test   %eax,%eax
8010313e:	0f 94 c0             	sete   %al
80103141:	0f b6 c0             	movzbl %al,%eax
80103144:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
80103147:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010314a:	89 04 24             	mov    %eax,(%esp)
8010314d:	e8 5c ff ff ff       	call   801030ae <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
80103152:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80103159:	e8 17 ff ff ff       	call   80103075 <cmos_read>
8010315e:	25 80 00 00 00       	and    $0x80,%eax
80103163:	85 c0                	test   %eax,%eax
80103165:	74 02                	je     80103169 <cmostime+0x48>
        continue;
80103167:	eb 36                	jmp    8010319f <cmostime+0x7e>
    fill_rtcdate(&t2);
80103169:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010316c:	89 04 24             	mov    %eax,(%esp)
8010316f:	e8 3a ff ff ff       	call   801030ae <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
80103174:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
8010317b:	00 
8010317c:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010317f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103183:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103186:	89 04 24             	mov    %eax,(%esp)
80103189:	e8 3b 21 00 00       	call   801052c9 <memcmp>
8010318e:	85 c0                	test   %eax,%eax
80103190:	75 0d                	jne    8010319f <cmostime+0x7e>
      break;
80103192:	90                   	nop
  }

  // convert
  if(bcd) {
80103193:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103197:	0f 84 ac 00 00 00    	je     80103249 <cmostime+0x128>
8010319d:	eb 02                	jmp    801031a1 <cmostime+0x80>
  }
8010319f:	eb a6                	jmp    80103147 <cmostime+0x26>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801031a1:	8b 45 d8             	mov    -0x28(%ebp),%eax
801031a4:	c1 e8 04             	shr    $0x4,%eax
801031a7:	89 c2                	mov    %eax,%edx
801031a9:	89 d0                	mov    %edx,%eax
801031ab:	c1 e0 02             	shl    $0x2,%eax
801031ae:	01 d0                	add    %edx,%eax
801031b0:	01 c0                	add    %eax,%eax
801031b2:	8b 55 d8             	mov    -0x28(%ebp),%edx
801031b5:	83 e2 0f             	and    $0xf,%edx
801031b8:	01 d0                	add    %edx,%eax
801031ba:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
801031bd:	8b 45 dc             	mov    -0x24(%ebp),%eax
801031c0:	c1 e8 04             	shr    $0x4,%eax
801031c3:	89 c2                	mov    %eax,%edx
801031c5:	89 d0                	mov    %edx,%eax
801031c7:	c1 e0 02             	shl    $0x2,%eax
801031ca:	01 d0                	add    %edx,%eax
801031cc:	01 c0                	add    %eax,%eax
801031ce:	8b 55 dc             	mov    -0x24(%ebp),%edx
801031d1:	83 e2 0f             	and    $0xf,%edx
801031d4:	01 d0                	add    %edx,%eax
801031d6:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
801031d9:	8b 45 e0             	mov    -0x20(%ebp),%eax
801031dc:	c1 e8 04             	shr    $0x4,%eax
801031df:	89 c2                	mov    %eax,%edx
801031e1:	89 d0                	mov    %edx,%eax
801031e3:	c1 e0 02             	shl    $0x2,%eax
801031e6:	01 d0                	add    %edx,%eax
801031e8:	01 c0                	add    %eax,%eax
801031ea:	8b 55 e0             	mov    -0x20(%ebp),%edx
801031ed:	83 e2 0f             	and    $0xf,%edx
801031f0:	01 d0                	add    %edx,%eax
801031f2:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
801031f5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801031f8:	c1 e8 04             	shr    $0x4,%eax
801031fb:	89 c2                	mov    %eax,%edx
801031fd:	89 d0                	mov    %edx,%eax
801031ff:	c1 e0 02             	shl    $0x2,%eax
80103202:	01 d0                	add    %edx,%eax
80103204:	01 c0                	add    %eax,%eax
80103206:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103209:	83 e2 0f             	and    $0xf,%edx
8010320c:	01 d0                	add    %edx,%eax
8010320e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
80103211:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103214:	c1 e8 04             	shr    $0x4,%eax
80103217:	89 c2                	mov    %eax,%edx
80103219:	89 d0                	mov    %edx,%eax
8010321b:	c1 e0 02             	shl    $0x2,%eax
8010321e:	01 d0                	add    %edx,%eax
80103220:	01 c0                	add    %eax,%eax
80103222:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103225:	83 e2 0f             	and    $0xf,%edx
80103228:	01 d0                	add    %edx,%eax
8010322a:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
8010322d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103230:	c1 e8 04             	shr    $0x4,%eax
80103233:	89 c2                	mov    %eax,%edx
80103235:	89 d0                	mov    %edx,%eax
80103237:	c1 e0 02             	shl    $0x2,%eax
8010323a:	01 d0                	add    %edx,%eax
8010323c:	01 c0                	add    %eax,%eax
8010323e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103241:	83 e2 0f             	and    $0xf,%edx
80103244:	01 d0                	add    %edx,%eax
80103246:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
80103249:	8b 45 08             	mov    0x8(%ebp),%eax
8010324c:	8b 55 d8             	mov    -0x28(%ebp),%edx
8010324f:	89 10                	mov    %edx,(%eax)
80103251:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103254:	89 50 04             	mov    %edx,0x4(%eax)
80103257:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010325a:	89 50 08             	mov    %edx,0x8(%eax)
8010325d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103260:	89 50 0c             	mov    %edx,0xc(%eax)
80103263:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103266:	89 50 10             	mov    %edx,0x10(%eax)
80103269:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010326c:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
8010326f:	8b 45 08             	mov    0x8(%ebp),%eax
80103272:	8b 40 14             	mov    0x14(%eax),%eax
80103275:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
8010327b:	8b 45 08             	mov    0x8(%ebp),%eax
8010327e:	89 50 14             	mov    %edx,0x14(%eax)
}
80103281:	c9                   	leave  
80103282:	c3                   	ret    

80103283 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
80103283:	55                   	push   %ebp
80103284:	89 e5                	mov    %esp,%ebp
80103286:	83 ec 38             	sub    $0x38,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103289:	c7 44 24 04 d9 86 10 	movl   $0x801086d9,0x4(%esp)
80103290:	80 
80103291:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
80103298:	e8 22 1d 00 00       	call   80104fbf <initlock>
  readsb(dev, &sb);
8010329d:	8d 45 dc             	lea    -0x24(%ebp),%eax
801032a0:	89 44 24 04          	mov    %eax,0x4(%esp)
801032a4:	8b 45 08             	mov    0x8(%ebp),%eax
801032a7:	89 04 24             	mov    %eax,(%esp)
801032aa:	e8 a1 e0 ff ff       	call   80101350 <readsb>
  log.start = sb.logstart;
801032af:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032b2:	a3 34 37 11 80       	mov    %eax,0x80113734
  log.size = sb.nlog;
801032b7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801032ba:	a3 38 37 11 80       	mov    %eax,0x80113738
  log.dev = dev;
801032bf:	8b 45 08             	mov    0x8(%ebp),%eax
801032c2:	a3 44 37 11 80       	mov    %eax,0x80113744
  recover_from_log();
801032c7:	e8 9a 01 00 00       	call   80103466 <recover_from_log>
}
801032cc:	c9                   	leave  
801032cd:	c3                   	ret    

801032ce <install_trans>:

// Copy committed blocks from log to their home location
static void
install_trans(void)
{
801032ce:	55                   	push   %ebp
801032cf:	89 e5                	mov    %esp,%ebp
801032d1:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801032d4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801032db:	e9 8c 00 00 00       	jmp    8010336c <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801032e0:	8b 15 34 37 11 80    	mov    0x80113734,%edx
801032e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032e9:	01 d0                	add    %edx,%eax
801032eb:	83 c0 01             	add    $0x1,%eax
801032ee:	89 c2                	mov    %eax,%edx
801032f0:	a1 44 37 11 80       	mov    0x80113744,%eax
801032f5:	89 54 24 04          	mov    %edx,0x4(%esp)
801032f9:	89 04 24             	mov    %eax,(%esp)
801032fc:	e8 b4 ce ff ff       	call   801001b5 <bread>
80103301:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80103304:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103307:	83 c0 10             	add    $0x10,%eax
8010330a:	8b 04 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%eax
80103311:	89 c2                	mov    %eax,%edx
80103313:	a1 44 37 11 80       	mov    0x80113744,%eax
80103318:	89 54 24 04          	mov    %edx,0x4(%esp)
8010331c:	89 04 24             	mov    %eax,(%esp)
8010331f:	e8 91 ce ff ff       	call   801001b5 <bread>
80103324:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103327:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010332a:	8d 50 5c             	lea    0x5c(%eax),%edx
8010332d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103330:	83 c0 5c             	add    $0x5c,%eax
80103333:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010333a:	00 
8010333b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010333f:	89 04 24             	mov    %eax,(%esp)
80103342:	e8 da 1f 00 00       	call   80105321 <memmove>
    bwrite(dbuf);  // write dst to disk
80103347:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010334a:	89 04 24             	mov    %eax,(%esp)
8010334d:	e8 9a ce ff ff       	call   801001ec <bwrite>
    brelse(lbuf);
80103352:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103355:	89 04 24             	mov    %eax,(%esp)
80103358:	e8 cf ce ff ff       	call   8010022c <brelse>
    brelse(dbuf);
8010335d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103360:	89 04 24             	mov    %eax,(%esp)
80103363:	e8 c4 ce ff ff       	call   8010022c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80103368:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010336c:	a1 48 37 11 80       	mov    0x80113748,%eax
80103371:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103374:	0f 8f 66 ff ff ff    	jg     801032e0 <install_trans+0x12>
  }
}
8010337a:	c9                   	leave  
8010337b:	c3                   	ret    

8010337c <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010337c:	55                   	push   %ebp
8010337d:	89 e5                	mov    %esp,%ebp
8010337f:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103382:	a1 34 37 11 80       	mov    0x80113734,%eax
80103387:	89 c2                	mov    %eax,%edx
80103389:	a1 44 37 11 80       	mov    0x80113744,%eax
8010338e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103392:	89 04 24             	mov    %eax,(%esp)
80103395:	e8 1b ce ff ff       	call   801001b5 <bread>
8010339a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
8010339d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033a0:	83 c0 5c             	add    $0x5c,%eax
801033a3:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
801033a6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033a9:	8b 00                	mov    (%eax),%eax
801033ab:	a3 48 37 11 80       	mov    %eax,0x80113748
  for (i = 0; i < log.lh.n; i++) {
801033b0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801033b7:	eb 1b                	jmp    801033d4 <read_head+0x58>
    log.lh.block[i] = lh->block[i];
801033b9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801033bf:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
801033c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801033c6:	83 c2 10             	add    $0x10,%edx
801033c9:	89 04 95 0c 37 11 80 	mov    %eax,-0x7feec8f4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
801033d0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801033d4:	a1 48 37 11 80       	mov    0x80113748,%eax
801033d9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801033dc:	7f db                	jg     801033b9 <read_head+0x3d>
  }
  brelse(buf);
801033de:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033e1:	89 04 24             	mov    %eax,(%esp)
801033e4:	e8 43 ce ff ff       	call   8010022c <brelse>
}
801033e9:	c9                   	leave  
801033ea:	c3                   	ret    

801033eb <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801033eb:	55                   	push   %ebp
801033ec:	89 e5                	mov    %esp,%ebp
801033ee:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801033f1:	a1 34 37 11 80       	mov    0x80113734,%eax
801033f6:	89 c2                	mov    %eax,%edx
801033f8:	a1 44 37 11 80       	mov    0x80113744,%eax
801033fd:	89 54 24 04          	mov    %edx,0x4(%esp)
80103401:	89 04 24             	mov    %eax,(%esp)
80103404:	e8 ac cd ff ff       	call   801001b5 <bread>
80103409:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
8010340c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010340f:	83 c0 5c             	add    $0x5c,%eax
80103412:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103415:	8b 15 48 37 11 80    	mov    0x80113748,%edx
8010341b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010341e:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103420:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103427:	eb 1b                	jmp    80103444 <write_head+0x59>
    hb->block[i] = log.lh.block[i];
80103429:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010342c:	83 c0 10             	add    $0x10,%eax
8010342f:	8b 0c 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%ecx
80103436:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103439:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010343c:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
80103440:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103444:	a1 48 37 11 80       	mov    0x80113748,%eax
80103449:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010344c:	7f db                	jg     80103429 <write_head+0x3e>
  }
  bwrite(buf);
8010344e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103451:	89 04 24             	mov    %eax,(%esp)
80103454:	e8 93 cd ff ff       	call   801001ec <bwrite>
  brelse(buf);
80103459:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010345c:	89 04 24             	mov    %eax,(%esp)
8010345f:	e8 c8 cd ff ff       	call   8010022c <brelse>
}
80103464:	c9                   	leave  
80103465:	c3                   	ret    

80103466 <recover_from_log>:

static void
recover_from_log(void)
{
80103466:	55                   	push   %ebp
80103467:	89 e5                	mov    %esp,%ebp
80103469:	83 ec 08             	sub    $0x8,%esp
  read_head();
8010346c:	e8 0b ff ff ff       	call   8010337c <read_head>
  install_trans(); // if committed, copy from log to disk
80103471:	e8 58 fe ff ff       	call   801032ce <install_trans>
  log.lh.n = 0;
80103476:	c7 05 48 37 11 80 00 	movl   $0x0,0x80113748
8010347d:	00 00 00 
  write_head(); // clear the log
80103480:	e8 66 ff ff ff       	call   801033eb <write_head>
}
80103485:	c9                   	leave  
80103486:	c3                   	ret    

80103487 <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103487:	55                   	push   %ebp
80103488:	89 e5                	mov    %esp,%ebp
8010348a:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
8010348d:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
80103494:	e8 47 1b 00 00       	call   80104fe0 <acquire>
  while(1){
    if(log.committing){
80103499:	a1 40 37 11 80       	mov    0x80113740,%eax
8010349e:	85 c0                	test   %eax,%eax
801034a0:	74 16                	je     801034b8 <begin_op+0x31>
      sleep(&log, &log.lock);
801034a2:	c7 44 24 04 00 37 11 	movl   $0x80113700,0x4(%esp)
801034a9:	80 
801034aa:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
801034b1:	e8 43 15 00 00       	call   801049f9 <sleep>
801034b6:	eb 4f                	jmp    80103507 <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
801034b8:	8b 0d 48 37 11 80    	mov    0x80113748,%ecx
801034be:	a1 3c 37 11 80       	mov    0x8011373c,%eax
801034c3:	8d 50 01             	lea    0x1(%eax),%edx
801034c6:	89 d0                	mov    %edx,%eax
801034c8:	c1 e0 02             	shl    $0x2,%eax
801034cb:	01 d0                	add    %edx,%eax
801034cd:	01 c0                	add    %eax,%eax
801034cf:	01 c8                	add    %ecx,%eax
801034d1:	83 f8 1e             	cmp    $0x1e,%eax
801034d4:	7e 16                	jle    801034ec <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
801034d6:	c7 44 24 04 00 37 11 	movl   $0x80113700,0x4(%esp)
801034dd:	80 
801034de:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
801034e5:	e8 0f 15 00 00       	call   801049f9 <sleep>
801034ea:	eb 1b                	jmp    80103507 <begin_op+0x80>
    } else {
      log.outstanding += 1;
801034ec:	a1 3c 37 11 80       	mov    0x8011373c,%eax
801034f1:	83 c0 01             	add    $0x1,%eax
801034f4:	a3 3c 37 11 80       	mov    %eax,0x8011373c
      release(&log.lock);
801034f9:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
80103500:	e8 43 1b 00 00       	call   80105048 <release>
      break;
80103505:	eb 02                	jmp    80103509 <begin_op+0x82>
    }
  }
80103507:	eb 90                	jmp    80103499 <begin_op+0x12>
}
80103509:	c9                   	leave  
8010350a:	c3                   	ret    

8010350b <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
8010350b:	55                   	push   %ebp
8010350c:	89 e5                	mov    %esp,%ebp
8010350e:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
80103511:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
80103518:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
8010351f:	e8 bc 1a 00 00       	call   80104fe0 <acquire>
  log.outstanding -= 1;
80103524:	a1 3c 37 11 80       	mov    0x8011373c,%eax
80103529:	83 e8 01             	sub    $0x1,%eax
8010352c:	a3 3c 37 11 80       	mov    %eax,0x8011373c
  if(log.committing)
80103531:	a1 40 37 11 80       	mov    0x80113740,%eax
80103536:	85 c0                	test   %eax,%eax
80103538:	74 0c                	je     80103546 <end_op+0x3b>
    panic("log.committing");
8010353a:	c7 04 24 dd 86 10 80 	movl   $0x801086dd,(%esp)
80103541:	e8 1c d0 ff ff       	call   80100562 <panic>
  if(log.outstanding == 0){
80103546:	a1 3c 37 11 80       	mov    0x8011373c,%eax
8010354b:	85 c0                	test   %eax,%eax
8010354d:	75 13                	jne    80103562 <end_op+0x57>
    do_commit = 1;
8010354f:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
80103556:	c7 05 40 37 11 80 01 	movl   $0x1,0x80113740
8010355d:	00 00 00 
80103560:	eb 0c                	jmp    8010356e <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
80103562:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
80103569:	e8 62 15 00 00       	call   80104ad0 <wakeup>
  }
  release(&log.lock);
8010356e:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
80103575:	e8 ce 1a 00 00       	call   80105048 <release>

  if(do_commit){
8010357a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010357e:	74 33                	je     801035b3 <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103580:	e8 de 00 00 00       	call   80103663 <commit>
    acquire(&log.lock);
80103585:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
8010358c:	e8 4f 1a 00 00       	call   80104fe0 <acquire>
    log.committing = 0;
80103591:	c7 05 40 37 11 80 00 	movl   $0x0,0x80113740
80103598:	00 00 00 
    wakeup(&log);
8010359b:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
801035a2:	e8 29 15 00 00       	call   80104ad0 <wakeup>
    release(&log.lock);
801035a7:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
801035ae:	e8 95 1a 00 00       	call   80105048 <release>
  }
}
801035b3:	c9                   	leave  
801035b4:	c3                   	ret    

801035b5 <write_log>:

// Copy modified blocks from cache to log.
static void
write_log(void)
{
801035b5:	55                   	push   %ebp
801035b6:	89 e5                	mov    %esp,%ebp
801035b8:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801035bb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801035c2:	e9 8c 00 00 00       	jmp    80103653 <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
801035c7:	8b 15 34 37 11 80    	mov    0x80113734,%edx
801035cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035d0:	01 d0                	add    %edx,%eax
801035d2:	83 c0 01             	add    $0x1,%eax
801035d5:	89 c2                	mov    %eax,%edx
801035d7:	a1 44 37 11 80       	mov    0x80113744,%eax
801035dc:	89 54 24 04          	mov    %edx,0x4(%esp)
801035e0:	89 04 24             	mov    %eax,(%esp)
801035e3:	e8 cd cb ff ff       	call   801001b5 <bread>
801035e8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801035eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035ee:	83 c0 10             	add    $0x10,%eax
801035f1:	8b 04 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%eax
801035f8:	89 c2                	mov    %eax,%edx
801035fa:	a1 44 37 11 80       	mov    0x80113744,%eax
801035ff:	89 54 24 04          	mov    %edx,0x4(%esp)
80103603:	89 04 24             	mov    %eax,(%esp)
80103606:	e8 aa cb ff ff       	call   801001b5 <bread>
8010360b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
8010360e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103611:	8d 50 5c             	lea    0x5c(%eax),%edx
80103614:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103617:	83 c0 5c             	add    $0x5c,%eax
8010361a:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103621:	00 
80103622:	89 54 24 04          	mov    %edx,0x4(%esp)
80103626:	89 04 24             	mov    %eax,(%esp)
80103629:	e8 f3 1c 00 00       	call   80105321 <memmove>
    bwrite(to);  // write the log
8010362e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103631:	89 04 24             	mov    %eax,(%esp)
80103634:	e8 b3 cb ff ff       	call   801001ec <bwrite>
    brelse(from);
80103639:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010363c:	89 04 24             	mov    %eax,(%esp)
8010363f:	e8 e8 cb ff ff       	call   8010022c <brelse>
    brelse(to);
80103644:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103647:	89 04 24             	mov    %eax,(%esp)
8010364a:	e8 dd cb ff ff       	call   8010022c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
8010364f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103653:	a1 48 37 11 80       	mov    0x80113748,%eax
80103658:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010365b:	0f 8f 66 ff ff ff    	jg     801035c7 <write_log+0x12>
  }
}
80103661:	c9                   	leave  
80103662:	c3                   	ret    

80103663 <commit>:

static void
commit()
{
80103663:	55                   	push   %ebp
80103664:	89 e5                	mov    %esp,%ebp
80103666:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103669:	a1 48 37 11 80       	mov    0x80113748,%eax
8010366e:	85 c0                	test   %eax,%eax
80103670:	7e 1e                	jle    80103690 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103672:	e8 3e ff ff ff       	call   801035b5 <write_log>
    write_head();    // Write header to disk -- the real commit
80103677:	e8 6f fd ff ff       	call   801033eb <write_head>
    install_trans(); // Now install writes to home locations
8010367c:	e8 4d fc ff ff       	call   801032ce <install_trans>
    log.lh.n = 0;
80103681:	c7 05 48 37 11 80 00 	movl   $0x0,0x80113748
80103688:	00 00 00 
    write_head();    // Erase the transaction from the log
8010368b:	e8 5b fd ff ff       	call   801033eb <write_head>
  }
}
80103690:	c9                   	leave  
80103691:	c3                   	ret    

80103692 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103692:	55                   	push   %ebp
80103693:	89 e5                	mov    %esp,%ebp
80103695:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103698:	a1 48 37 11 80       	mov    0x80113748,%eax
8010369d:	83 f8 1d             	cmp    $0x1d,%eax
801036a0:	7f 12                	jg     801036b4 <log_write+0x22>
801036a2:	a1 48 37 11 80       	mov    0x80113748,%eax
801036a7:	8b 15 38 37 11 80    	mov    0x80113738,%edx
801036ad:	83 ea 01             	sub    $0x1,%edx
801036b0:	39 d0                	cmp    %edx,%eax
801036b2:	7c 0c                	jl     801036c0 <log_write+0x2e>
    panic("too big a transaction");
801036b4:	c7 04 24 ec 86 10 80 	movl   $0x801086ec,(%esp)
801036bb:	e8 a2 ce ff ff       	call   80100562 <panic>
  if (log.outstanding < 1)
801036c0:	a1 3c 37 11 80       	mov    0x8011373c,%eax
801036c5:	85 c0                	test   %eax,%eax
801036c7:	7f 0c                	jg     801036d5 <log_write+0x43>
    panic("log_write outside of trans");
801036c9:	c7 04 24 02 87 10 80 	movl   $0x80108702,(%esp)
801036d0:	e8 8d ce ff ff       	call   80100562 <panic>

  acquire(&log.lock);
801036d5:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
801036dc:	e8 ff 18 00 00       	call   80104fe0 <acquire>
  for (i = 0; i < log.lh.n; i++) {
801036e1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801036e8:	eb 1f                	jmp    80103709 <log_write+0x77>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
801036ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036ed:	83 c0 10             	add    $0x10,%eax
801036f0:	8b 04 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%eax
801036f7:	89 c2                	mov    %eax,%edx
801036f9:	8b 45 08             	mov    0x8(%ebp),%eax
801036fc:	8b 40 08             	mov    0x8(%eax),%eax
801036ff:	39 c2                	cmp    %eax,%edx
80103701:	75 02                	jne    80103705 <log_write+0x73>
      break;
80103703:	eb 0e                	jmp    80103713 <log_write+0x81>
  for (i = 0; i < log.lh.n; i++) {
80103705:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103709:	a1 48 37 11 80       	mov    0x80113748,%eax
8010370e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103711:	7f d7                	jg     801036ea <log_write+0x58>
  }
  log.lh.block[i] = b->blockno;
80103713:	8b 45 08             	mov    0x8(%ebp),%eax
80103716:	8b 40 08             	mov    0x8(%eax),%eax
80103719:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010371c:	83 c2 10             	add    $0x10,%edx
8010371f:	89 04 95 0c 37 11 80 	mov    %eax,-0x7feec8f4(,%edx,4)
  if (i == log.lh.n)
80103726:	a1 48 37 11 80       	mov    0x80113748,%eax
8010372b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010372e:	75 0d                	jne    8010373d <log_write+0xab>
    log.lh.n++;
80103730:	a1 48 37 11 80       	mov    0x80113748,%eax
80103735:	83 c0 01             	add    $0x1,%eax
80103738:	a3 48 37 11 80       	mov    %eax,0x80113748
  b->flags |= B_DIRTY; // prevent eviction
8010373d:	8b 45 08             	mov    0x8(%ebp),%eax
80103740:	8b 00                	mov    (%eax),%eax
80103742:	83 c8 04             	or     $0x4,%eax
80103745:	89 c2                	mov    %eax,%edx
80103747:	8b 45 08             	mov    0x8(%ebp),%eax
8010374a:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
8010374c:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
80103753:	e8 f0 18 00 00       	call   80105048 <release>
}
80103758:	c9                   	leave  
80103759:	c3                   	ret    

8010375a <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
8010375a:	55                   	push   %ebp
8010375b:	89 e5                	mov    %esp,%ebp
8010375d:	83 ec 10             	sub    $0x10,%esp
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103760:	8b 55 08             	mov    0x8(%ebp),%edx
80103763:	8b 45 0c             	mov    0xc(%ebp),%eax
80103766:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103769:	f0 87 02             	lock xchg %eax,(%edx)
8010376c:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010376f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103772:	c9                   	leave  
80103773:	c3                   	ret    

80103774 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103774:	55                   	push   %ebp
80103775:	89 e5                	mov    %esp,%ebp
80103777:	83 e4 f0             	and    $0xfffffff0,%esp
8010377a:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
8010377d:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103784:	80 
80103785:	c7 04 24 28 67 11 80 	movl   $0x80116728,(%esp)
8010378c:	e8 ed f2 ff ff       	call   80102a7e <kinit1>
  kvmalloc();      // kernel page table
80103791:	e8 c1 44 00 00       	call   80107c57 <kvmalloc>
  mpinit();        // detect other processors
80103796:	e8 cb 03 00 00       	call   80103b66 <mpinit>
  lapicinit();     // interrupt controller
8010379b:	e8 36 f6 ff ff       	call   80102dd6 <lapicinit>
  seginit();       // segment descriptors
801037a0:	e8 7e 3f 00 00       	call   80107723 <seginit>
  picinit();       // disable pic
801037a5:	e8 0b 05 00 00       	call   80103cb5 <picinit>
  ioapicinit();    // another interrupt controller
801037aa:	e8 eb f1 ff ff       	call   8010299a <ioapicinit>
  consoleinit();   // console hardware
801037af:	e8 1c d3 ff ff       	call   80100ad0 <consoleinit>
  uartinit();      // serial port
801037b4:	e8 f4 32 00 00       	call   80106aad <uartinit>
  pinit();         // process table
801037b9:	e8 f0 08 00 00       	call   801040ae <pinit>
  tvinit();        // trap vectors
801037be:	e8 b3 2e 00 00       	call   80106676 <tvinit>
  binit();         // buffer cache
801037c3:	e8 6c c8 ff ff       	call   80100034 <binit>
  fileinit();      // file table
801037c8:	e8 9c d7 ff ff       	call   80100f69 <fileinit>
  ideinit();       // disk 
801037cd:	e8 d2 ed ff ff       	call   801025a4 <ideinit>
  startothers();   // start other processors
801037d2:	e8 83 00 00 00       	call   8010385a <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801037d7:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801037de:	8e 
801037df:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801037e6:	e8 cb f2 ff ff       	call   80102ab6 <kinit2>
  userinit();      // first user process
801037eb:	e8 9c 0a 00 00       	call   8010428c <userinit>
  mpmain();        // finish this processor's setup
801037f0:	e8 1a 00 00 00       	call   8010380f <mpmain>

801037f5 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801037f5:	55                   	push   %ebp
801037f6:	89 e5                	mov    %esp,%ebp
801037f8:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
801037fb:	e8 6e 44 00 00       	call   80107c6e <switchkvm>
  seginit();
80103800:	e8 1e 3f 00 00       	call   80107723 <seginit>
  lapicinit();
80103805:	e8 cc f5 ff ff       	call   80102dd6 <lapicinit>
  mpmain();
8010380a:	e8 00 00 00 00       	call   8010380f <mpmain>

8010380f <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
8010380f:	55                   	push   %ebp
80103810:	89 e5                	mov    %esp,%ebp
80103812:	53                   	push   %ebx
80103813:	83 ec 14             	sub    $0x14,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80103816:	e8 af 08 00 00       	call   801040ca <cpuid>
8010381b:	89 c3                	mov    %eax,%ebx
8010381d:	e8 a8 08 00 00       	call   801040ca <cpuid>
80103822:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80103826:	89 44 24 04          	mov    %eax,0x4(%esp)
8010382a:	c7 04 24 1d 87 10 80 	movl   $0x8010871d,(%esp)
80103831:	e8 92 cb ff ff       	call   801003c8 <cprintf>
  idtinit();       // load idt register
80103836:	e8 af 2f 00 00       	call   801067ea <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
8010383b:	e8 ab 08 00 00       	call   801040eb <mycpu>
80103840:	05 a0 00 00 00       	add    $0xa0,%eax
80103845:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010384c:	00 
8010384d:	89 04 24             	mov    %eax,(%esp)
80103850:	e8 05 ff ff ff       	call   8010375a <xchg>
  scheduler();     // start running processes
80103855:	e8 d2 0f 00 00       	call   8010482c <scheduler>

8010385a <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
8010385a:	55                   	push   %ebp
8010385b:	89 e5                	mov    %esp,%ebp
8010385d:	83 ec 28             	sub    $0x28,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
80103860:	c7 45 f0 00 70 00 80 	movl   $0x80007000,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103867:	b8 8a 00 00 00       	mov    $0x8a,%eax
8010386c:	89 44 24 08          	mov    %eax,0x8(%esp)
80103870:	c7 44 24 04 ec b4 10 	movl   $0x8010b4ec,0x4(%esp)
80103877:	80 
80103878:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010387b:	89 04 24             	mov    %eax,(%esp)
8010387e:	e8 9e 1a 00 00       	call   80105321 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103883:	c7 45 f4 00 38 11 80 	movl   $0x80113800,-0xc(%ebp)
8010388a:	eb 76                	jmp    80103902 <startothers+0xa8>
    if(c == mycpu())  // We've started already.
8010388c:	e8 5a 08 00 00       	call   801040eb <mycpu>
80103891:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103894:	75 02                	jne    80103898 <startothers+0x3e>
      continue;
80103896:	eb 63                	jmp    801038fb <startothers+0xa1>

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103898:	e8 0c f3 ff ff       	call   80102ba9 <kalloc>
8010389d:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
801038a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038a3:	83 e8 04             	sub    $0x4,%eax
801038a6:	8b 55 ec             	mov    -0x14(%ebp),%edx
801038a9:	81 c2 00 10 00 00    	add    $0x1000,%edx
801038af:	89 10                	mov    %edx,(%eax)
    *(void(**)(void))(code-8) = mpenter;
801038b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038b4:	83 e8 08             	sub    $0x8,%eax
801038b7:	c7 00 f5 37 10 80    	movl   $0x801037f5,(%eax)
    *(int**)(code-12) = (void *) V2P(entrypgdir);
801038bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038c0:	8d 50 f4             	lea    -0xc(%eax),%edx
801038c3:	b8 00 a0 10 80       	mov    $0x8010a000,%eax
801038c8:	05 00 00 00 80       	add    $0x80000000,%eax
801038cd:	89 02                	mov    %eax,(%edx)

    lapicstartap(c->apicid, V2P(code));
801038cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038d2:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
801038d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038db:	0f b6 00             	movzbl (%eax),%eax
801038de:	0f b6 c0             	movzbl %al,%eax
801038e1:	89 54 24 04          	mov    %edx,0x4(%esp)
801038e5:	89 04 24             	mov    %eax,(%esp)
801038e8:	e8 8e f6 ff ff       	call   80102f7b <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
801038ed:	90                   	nop
801038ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038f1:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
801038f7:	85 c0                	test   %eax,%eax
801038f9:	74 f3                	je     801038ee <startothers+0x94>
  for(c = cpus; c < cpus+ncpu; c++){
801038fb:	81 45 f4 b0 00 00 00 	addl   $0xb0,-0xc(%ebp)
80103902:	a1 80 3d 11 80       	mov    0x80113d80,%eax
80103907:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
8010390d:	05 00 38 11 80       	add    $0x80113800,%eax
80103912:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103915:	0f 87 71 ff ff ff    	ja     8010388c <startothers+0x32>
      ;
  }
}
8010391b:	c9                   	leave  
8010391c:	c3                   	ret    

8010391d <inb>:
{
8010391d:	55                   	push   %ebp
8010391e:	89 e5                	mov    %esp,%ebp
80103920:	83 ec 14             	sub    $0x14,%esp
80103923:	8b 45 08             	mov    0x8(%ebp),%eax
80103926:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010392a:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010392e:	89 c2                	mov    %eax,%edx
80103930:	ec                   	in     (%dx),%al
80103931:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103934:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103938:	c9                   	leave  
80103939:	c3                   	ret    

8010393a <outb>:
{
8010393a:	55                   	push   %ebp
8010393b:	89 e5                	mov    %esp,%ebp
8010393d:	83 ec 08             	sub    $0x8,%esp
80103940:	8b 55 08             	mov    0x8(%ebp),%edx
80103943:	8b 45 0c             	mov    0xc(%ebp),%eax
80103946:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010394a:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010394d:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103951:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103955:	ee                   	out    %al,(%dx)
}
80103956:	c9                   	leave  
80103957:	c3                   	ret    

80103958 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80103958:	55                   	push   %ebp
80103959:	89 e5                	mov    %esp,%ebp
8010395b:	83 ec 10             	sub    $0x10,%esp
  int i, sum;

  sum = 0;
8010395e:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103965:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010396c:	eb 15                	jmp    80103983 <sum+0x2b>
    sum += addr[i];
8010396e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80103971:	8b 45 08             	mov    0x8(%ebp),%eax
80103974:	01 d0                	add    %edx,%eax
80103976:	0f b6 00             	movzbl (%eax),%eax
80103979:	0f b6 c0             	movzbl %al,%eax
8010397c:	01 45 f8             	add    %eax,-0x8(%ebp)
  for(i=0; i<len; i++)
8010397f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103983:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103986:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103989:	7c e3                	jl     8010396e <sum+0x16>
  return sum;
8010398b:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010398e:	c9                   	leave  
8010398f:	c3                   	ret    

80103990 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103990:	55                   	push   %ebp
80103991:	89 e5                	mov    %esp,%ebp
80103993:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = P2V(a);
80103996:	8b 45 08             	mov    0x8(%ebp),%eax
80103999:	05 00 00 00 80       	add    $0x80000000,%eax
8010399e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
801039a1:	8b 55 0c             	mov    0xc(%ebp),%edx
801039a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039a7:	01 d0                	add    %edx,%eax
801039a9:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
801039ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039af:	89 45 f4             	mov    %eax,-0xc(%ebp)
801039b2:	eb 3f                	jmp    801039f3 <mpsearch1+0x63>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
801039b4:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801039bb:	00 
801039bc:	c7 44 24 04 34 87 10 	movl   $0x80108734,0x4(%esp)
801039c3:	80 
801039c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039c7:	89 04 24             	mov    %eax,(%esp)
801039ca:	e8 fa 18 00 00       	call   801052c9 <memcmp>
801039cf:	85 c0                	test   %eax,%eax
801039d1:	75 1c                	jne    801039ef <mpsearch1+0x5f>
801039d3:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
801039da:	00 
801039db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039de:	89 04 24             	mov    %eax,(%esp)
801039e1:	e8 72 ff ff ff       	call   80103958 <sum>
801039e6:	84 c0                	test   %al,%al
801039e8:	75 05                	jne    801039ef <mpsearch1+0x5f>
      return (struct mp*)p;
801039ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039ed:	eb 11                	jmp    80103a00 <mpsearch1+0x70>
  for(p = addr; p < e; p += sizeof(struct mp))
801039ef:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801039f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039f6:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801039f9:	72 b9                	jb     801039b4 <mpsearch1+0x24>
  return 0;
801039fb:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103a00:	c9                   	leave  
80103a01:	c3                   	ret    

80103a02 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103a02:	55                   	push   %ebp
80103a03:	89 e5                	mov    %esp,%ebp
80103a05:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103a08:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103a0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a12:	83 c0 0f             	add    $0xf,%eax
80103a15:	0f b6 00             	movzbl (%eax),%eax
80103a18:	0f b6 c0             	movzbl %al,%eax
80103a1b:	c1 e0 08             	shl    $0x8,%eax
80103a1e:	89 c2                	mov    %eax,%edx
80103a20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a23:	83 c0 0e             	add    $0xe,%eax
80103a26:	0f b6 00             	movzbl (%eax),%eax
80103a29:	0f b6 c0             	movzbl %al,%eax
80103a2c:	09 d0                	or     %edx,%eax
80103a2e:	c1 e0 04             	shl    $0x4,%eax
80103a31:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103a34:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103a38:	74 21                	je     80103a5b <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103a3a:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103a41:	00 
80103a42:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a45:	89 04 24             	mov    %eax,(%esp)
80103a48:	e8 43 ff ff ff       	call   80103990 <mpsearch1>
80103a4d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103a50:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103a54:	74 50                	je     80103aa6 <mpsearch+0xa4>
      return mp;
80103a56:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a59:	eb 5f                	jmp    80103aba <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103a5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a5e:	83 c0 14             	add    $0x14,%eax
80103a61:	0f b6 00             	movzbl (%eax),%eax
80103a64:	0f b6 c0             	movzbl %al,%eax
80103a67:	c1 e0 08             	shl    $0x8,%eax
80103a6a:	89 c2                	mov    %eax,%edx
80103a6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a6f:	83 c0 13             	add    $0x13,%eax
80103a72:	0f b6 00             	movzbl (%eax),%eax
80103a75:	0f b6 c0             	movzbl %al,%eax
80103a78:	09 d0                	or     %edx,%eax
80103a7a:	c1 e0 0a             	shl    $0xa,%eax
80103a7d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103a80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a83:	2d 00 04 00 00       	sub    $0x400,%eax
80103a88:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103a8f:	00 
80103a90:	89 04 24             	mov    %eax,(%esp)
80103a93:	e8 f8 fe ff ff       	call   80103990 <mpsearch1>
80103a98:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103a9b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103a9f:	74 05                	je     80103aa6 <mpsearch+0xa4>
      return mp;
80103aa1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103aa4:	eb 14                	jmp    80103aba <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103aa6:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103aad:	00 
80103aae:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103ab5:	e8 d6 fe ff ff       	call   80103990 <mpsearch1>
}
80103aba:	c9                   	leave  
80103abb:	c3                   	ret    

80103abc <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103abc:	55                   	push   %ebp
80103abd:	89 e5                	mov    %esp,%ebp
80103abf:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103ac2:	e8 3b ff ff ff       	call   80103a02 <mpsearch>
80103ac7:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103aca:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103ace:	74 0a                	je     80103ada <mpconfig+0x1e>
80103ad0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ad3:	8b 40 04             	mov    0x4(%eax),%eax
80103ad6:	85 c0                	test   %eax,%eax
80103ad8:	75 0a                	jne    80103ae4 <mpconfig+0x28>
    return 0;
80103ada:	b8 00 00 00 00       	mov    $0x0,%eax
80103adf:	e9 80 00 00 00       	jmp    80103b64 <mpconfig+0xa8>
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80103ae4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ae7:	8b 40 04             	mov    0x4(%eax),%eax
80103aea:	05 00 00 00 80       	add    $0x80000000,%eax
80103aef:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103af2:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103af9:	00 
80103afa:	c7 44 24 04 39 87 10 	movl   $0x80108739,0x4(%esp)
80103b01:	80 
80103b02:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b05:	89 04 24             	mov    %eax,(%esp)
80103b08:	e8 bc 17 00 00       	call   801052c9 <memcmp>
80103b0d:	85 c0                	test   %eax,%eax
80103b0f:	74 07                	je     80103b18 <mpconfig+0x5c>
    return 0;
80103b11:	b8 00 00 00 00       	mov    $0x0,%eax
80103b16:	eb 4c                	jmp    80103b64 <mpconfig+0xa8>
  if(conf->version != 1 && conf->version != 4)
80103b18:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b1b:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103b1f:	3c 01                	cmp    $0x1,%al
80103b21:	74 12                	je     80103b35 <mpconfig+0x79>
80103b23:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b26:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103b2a:	3c 04                	cmp    $0x4,%al
80103b2c:	74 07                	je     80103b35 <mpconfig+0x79>
    return 0;
80103b2e:	b8 00 00 00 00       	mov    $0x0,%eax
80103b33:	eb 2f                	jmp    80103b64 <mpconfig+0xa8>
  if(sum((uchar*)conf, conf->length) != 0)
80103b35:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b38:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103b3c:	0f b7 c0             	movzwl %ax,%eax
80103b3f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b43:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b46:	89 04 24             	mov    %eax,(%esp)
80103b49:	e8 0a fe ff ff       	call   80103958 <sum>
80103b4e:	84 c0                	test   %al,%al
80103b50:	74 07                	je     80103b59 <mpconfig+0x9d>
    return 0;
80103b52:	b8 00 00 00 00       	mov    $0x0,%eax
80103b57:	eb 0b                	jmp    80103b64 <mpconfig+0xa8>
  *pmp = mp;
80103b59:	8b 45 08             	mov    0x8(%ebp),%eax
80103b5c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b5f:	89 10                	mov    %edx,(%eax)
  return conf;
80103b61:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103b64:	c9                   	leave  
80103b65:	c3                   	ret    

80103b66 <mpinit>:

void
mpinit(void)
{
80103b66:	55                   	push   %ebp
80103b67:	89 e5                	mov    %esp,%ebp
80103b69:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80103b6c:	8d 45 dc             	lea    -0x24(%ebp),%eax
80103b6f:	89 04 24             	mov    %eax,(%esp)
80103b72:	e8 45 ff ff ff       	call   80103abc <mpconfig>
80103b77:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103b7a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103b7e:	75 0c                	jne    80103b8c <mpinit+0x26>
    panic("Expect to run on an SMP");
80103b80:	c7 04 24 3e 87 10 80 	movl   $0x8010873e,(%esp)
80103b87:	e8 d6 c9 ff ff       	call   80100562 <panic>
  ismp = 1;
80103b8c:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
  lapic = (uint*)conf->lapicaddr;
80103b93:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b96:	8b 40 24             	mov    0x24(%eax),%eax
80103b99:	a3 fc 36 11 80       	mov    %eax,0x801136fc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103b9e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103ba1:	83 c0 2c             	add    $0x2c,%eax
80103ba4:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103ba7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103baa:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103bae:	0f b7 d0             	movzwl %ax,%edx
80103bb1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103bb4:	01 d0                	add    %edx,%eax
80103bb6:	89 45 e8             	mov    %eax,-0x18(%ebp)
80103bb9:	eb 7b                	jmp    80103c36 <mpinit+0xd0>
    switch(*p){
80103bbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bbe:	0f b6 00             	movzbl (%eax),%eax
80103bc1:	0f b6 c0             	movzbl %al,%eax
80103bc4:	83 f8 04             	cmp    $0x4,%eax
80103bc7:	77 65                	ja     80103c2e <mpinit+0xc8>
80103bc9:	8b 04 85 78 87 10 80 	mov    -0x7fef7888(,%eax,4),%eax
80103bd0:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103bd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bd5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(ncpu < NCPU) {
80103bd8:	a1 80 3d 11 80       	mov    0x80113d80,%eax
80103bdd:	83 f8 07             	cmp    $0x7,%eax
80103be0:	7f 28                	jg     80103c0a <mpinit+0xa4>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80103be2:	8b 15 80 3d 11 80    	mov    0x80113d80,%edx
80103be8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103beb:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103bef:	69 d2 b0 00 00 00    	imul   $0xb0,%edx,%edx
80103bf5:	81 c2 00 38 11 80    	add    $0x80113800,%edx
80103bfb:	88 02                	mov    %al,(%edx)
        ncpu++;
80103bfd:	a1 80 3d 11 80       	mov    0x80113d80,%eax
80103c02:	83 c0 01             	add    $0x1,%eax
80103c05:	a3 80 3d 11 80       	mov    %eax,0x80113d80
      }
      p += sizeof(struct mpproc);
80103c0a:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103c0e:	eb 26                	jmp    80103c36 <mpinit+0xd0>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103c10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c13:	89 45 e0             	mov    %eax,-0x20(%ebp)
      ioapicid = ioapic->apicno;
80103c16:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103c19:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103c1d:	a2 e0 37 11 80       	mov    %al,0x801137e0
      p += sizeof(struct mpioapic);
80103c22:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103c26:	eb 0e                	jmp    80103c36 <mpinit+0xd0>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103c28:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103c2c:	eb 08                	jmp    80103c36 <mpinit+0xd0>
    default:
      ismp = 0;
80103c2e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      break;
80103c35:	90                   	nop
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103c36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c39:	3b 45 e8             	cmp    -0x18(%ebp),%eax
80103c3c:	0f 82 79 ff ff ff    	jb     80103bbb <mpinit+0x55>
    }
  }
  if(!ismp)
80103c42:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103c46:	75 0c                	jne    80103c54 <mpinit+0xee>
    panic("Didn't find a suitable machine");
80103c48:	c7 04 24 58 87 10 80 	movl   $0x80108758,(%esp)
80103c4f:	e8 0e c9 ff ff       	call   80100562 <panic>

  if(mp->imcrp){
80103c54:	8b 45 dc             	mov    -0x24(%ebp),%eax
80103c57:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103c5b:	84 c0                	test   %al,%al
80103c5d:	74 36                	je     80103c95 <mpinit+0x12f>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103c5f:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103c66:	00 
80103c67:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103c6e:	e8 c7 fc ff ff       	call   8010393a <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103c73:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103c7a:	e8 9e fc ff ff       	call   8010391d <inb>
80103c7f:	83 c8 01             	or     $0x1,%eax
80103c82:	0f b6 c0             	movzbl %al,%eax
80103c85:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c89:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103c90:	e8 a5 fc ff ff       	call   8010393a <outb>
  }
}
80103c95:	c9                   	leave  
80103c96:	c3                   	ret    

80103c97 <outb>:
{
80103c97:	55                   	push   %ebp
80103c98:	89 e5                	mov    %esp,%ebp
80103c9a:	83 ec 08             	sub    $0x8,%esp
80103c9d:	8b 55 08             	mov    0x8(%ebp),%edx
80103ca0:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ca3:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103ca7:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103caa:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103cae:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103cb2:	ee                   	out    %al,(%dx)
}
80103cb3:	c9                   	leave  
80103cb4:	c3                   	ret    

80103cb5 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80103cb5:	55                   	push   %ebp
80103cb6:	89 e5                	mov    %esp,%ebp
80103cb8:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103cbb:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103cc2:	00 
80103cc3:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103cca:	e8 c8 ff ff ff       	call   80103c97 <outb>
  outb(IO_PIC2+1, 0xFF);
80103ccf:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103cd6:	00 
80103cd7:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103cde:	e8 b4 ff ff ff       	call   80103c97 <outb>
}
80103ce3:	c9                   	leave  
80103ce4:	c3                   	ret    

80103ce5 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103ce5:	55                   	push   %ebp
80103ce6:	89 e5                	mov    %esp,%ebp
80103ce8:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80103ceb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103cf2:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cf5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103cfb:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cfe:	8b 10                	mov    (%eax),%edx
80103d00:	8b 45 08             	mov    0x8(%ebp),%eax
80103d03:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103d05:	e8 7b d2 ff ff       	call   80100f85 <filealloc>
80103d0a:	8b 55 08             	mov    0x8(%ebp),%edx
80103d0d:	89 02                	mov    %eax,(%edx)
80103d0f:	8b 45 08             	mov    0x8(%ebp),%eax
80103d12:	8b 00                	mov    (%eax),%eax
80103d14:	85 c0                	test   %eax,%eax
80103d16:	0f 84 c8 00 00 00    	je     80103de4 <pipealloc+0xff>
80103d1c:	e8 64 d2 ff ff       	call   80100f85 <filealloc>
80103d21:	8b 55 0c             	mov    0xc(%ebp),%edx
80103d24:	89 02                	mov    %eax,(%edx)
80103d26:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d29:	8b 00                	mov    (%eax),%eax
80103d2b:	85 c0                	test   %eax,%eax
80103d2d:	0f 84 b1 00 00 00    	je     80103de4 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103d33:	e8 71 ee ff ff       	call   80102ba9 <kalloc>
80103d38:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103d3b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103d3f:	75 05                	jne    80103d46 <pipealloc+0x61>
    goto bad;
80103d41:	e9 9e 00 00 00       	jmp    80103de4 <pipealloc+0xff>
  p->readopen = 1;
80103d46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d49:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103d50:	00 00 00 
  p->writeopen = 1;
80103d53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d56:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103d5d:	00 00 00 
  p->nwrite = 0;
80103d60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d63:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103d6a:	00 00 00 
  p->nread = 0;
80103d6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d70:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103d77:	00 00 00 
  initlock(&p->lock, "pipe");
80103d7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d7d:	c7 44 24 04 8c 87 10 	movl   $0x8010878c,0x4(%esp)
80103d84:	80 
80103d85:	89 04 24             	mov    %eax,(%esp)
80103d88:	e8 32 12 00 00       	call   80104fbf <initlock>
  (*f0)->type = FD_PIPE;
80103d8d:	8b 45 08             	mov    0x8(%ebp),%eax
80103d90:	8b 00                	mov    (%eax),%eax
80103d92:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103d98:	8b 45 08             	mov    0x8(%ebp),%eax
80103d9b:	8b 00                	mov    (%eax),%eax
80103d9d:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103da1:	8b 45 08             	mov    0x8(%ebp),%eax
80103da4:	8b 00                	mov    (%eax),%eax
80103da6:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103daa:	8b 45 08             	mov    0x8(%ebp),%eax
80103dad:	8b 00                	mov    (%eax),%eax
80103daf:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103db2:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103db5:	8b 45 0c             	mov    0xc(%ebp),%eax
80103db8:	8b 00                	mov    (%eax),%eax
80103dba:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103dc0:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dc3:	8b 00                	mov    (%eax),%eax
80103dc5:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103dc9:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dcc:	8b 00                	mov    (%eax),%eax
80103dce:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103dd2:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dd5:	8b 00                	mov    (%eax),%eax
80103dd7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103dda:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80103ddd:	b8 00 00 00 00       	mov    $0x0,%eax
80103de2:	eb 42                	jmp    80103e26 <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
80103de4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103de8:	74 0b                	je     80103df5 <pipealloc+0x110>
    kfree((char*)p);
80103dea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ded:	89 04 24             	mov    %eax,(%esp)
80103df0:	e8 1e ed ff ff       	call   80102b13 <kfree>
  if(*f0)
80103df5:	8b 45 08             	mov    0x8(%ebp),%eax
80103df8:	8b 00                	mov    (%eax),%eax
80103dfa:	85 c0                	test   %eax,%eax
80103dfc:	74 0d                	je     80103e0b <pipealloc+0x126>
    fileclose(*f0);
80103dfe:	8b 45 08             	mov    0x8(%ebp),%eax
80103e01:	8b 00                	mov    (%eax),%eax
80103e03:	89 04 24             	mov    %eax,(%esp)
80103e06:	e8 22 d2 ff ff       	call   8010102d <fileclose>
  if(*f1)
80103e0b:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e0e:	8b 00                	mov    (%eax),%eax
80103e10:	85 c0                	test   %eax,%eax
80103e12:	74 0d                	je     80103e21 <pipealloc+0x13c>
    fileclose(*f1);
80103e14:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e17:	8b 00                	mov    (%eax),%eax
80103e19:	89 04 24             	mov    %eax,(%esp)
80103e1c:	e8 0c d2 ff ff       	call   8010102d <fileclose>
  return -1;
80103e21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103e26:	c9                   	leave  
80103e27:	c3                   	ret    

80103e28 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103e28:	55                   	push   %ebp
80103e29:	89 e5                	mov    %esp,%ebp
80103e2b:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80103e2e:	8b 45 08             	mov    0x8(%ebp),%eax
80103e31:	89 04 24             	mov    %eax,(%esp)
80103e34:	e8 a7 11 00 00       	call   80104fe0 <acquire>
  if(writable){
80103e39:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103e3d:	74 1f                	je     80103e5e <pipeclose+0x36>
    p->writeopen = 0;
80103e3f:	8b 45 08             	mov    0x8(%ebp),%eax
80103e42:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80103e49:	00 00 00 
    wakeup(&p->nread);
80103e4c:	8b 45 08             	mov    0x8(%ebp),%eax
80103e4f:	05 34 02 00 00       	add    $0x234,%eax
80103e54:	89 04 24             	mov    %eax,(%esp)
80103e57:	e8 74 0c 00 00       	call   80104ad0 <wakeup>
80103e5c:	eb 1d                	jmp    80103e7b <pipeclose+0x53>
  } else {
    p->readopen = 0;
80103e5e:	8b 45 08             	mov    0x8(%ebp),%eax
80103e61:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80103e68:	00 00 00 
    wakeup(&p->nwrite);
80103e6b:	8b 45 08             	mov    0x8(%ebp),%eax
80103e6e:	05 38 02 00 00       	add    $0x238,%eax
80103e73:	89 04 24             	mov    %eax,(%esp)
80103e76:	e8 55 0c 00 00       	call   80104ad0 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103e7b:	8b 45 08             	mov    0x8(%ebp),%eax
80103e7e:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103e84:	85 c0                	test   %eax,%eax
80103e86:	75 25                	jne    80103ead <pipeclose+0x85>
80103e88:	8b 45 08             	mov    0x8(%ebp),%eax
80103e8b:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103e91:	85 c0                	test   %eax,%eax
80103e93:	75 18                	jne    80103ead <pipeclose+0x85>
    release(&p->lock);
80103e95:	8b 45 08             	mov    0x8(%ebp),%eax
80103e98:	89 04 24             	mov    %eax,(%esp)
80103e9b:	e8 a8 11 00 00       	call   80105048 <release>
    kfree((char*)p);
80103ea0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ea3:	89 04 24             	mov    %eax,(%esp)
80103ea6:	e8 68 ec ff ff       	call   80102b13 <kfree>
80103eab:	eb 0b                	jmp    80103eb8 <pipeclose+0x90>
  } else
    release(&p->lock);
80103ead:	8b 45 08             	mov    0x8(%ebp),%eax
80103eb0:	89 04 24             	mov    %eax,(%esp)
80103eb3:	e8 90 11 00 00       	call   80105048 <release>
}
80103eb8:	c9                   	leave  
80103eb9:	c3                   	ret    

80103eba <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80103eba:	55                   	push   %ebp
80103ebb:	89 e5                	mov    %esp,%ebp
80103ebd:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
80103ec0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ec3:	89 04 24             	mov    %eax,(%esp)
80103ec6:	e8 15 11 00 00       	call   80104fe0 <acquire>
  for(i = 0; i < n; i++){
80103ecb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103ed2:	e9 a5 00 00 00       	jmp    80103f7c <pipewrite+0xc2>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103ed7:	eb 56                	jmp    80103f2f <pipewrite+0x75>
      if(p->readopen == 0 || myproc()->killed){
80103ed9:	8b 45 08             	mov    0x8(%ebp),%eax
80103edc:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103ee2:	85 c0                	test   %eax,%eax
80103ee4:	74 0c                	je     80103ef2 <pipewrite+0x38>
80103ee6:	e8 76 02 00 00       	call   80104161 <myproc>
80103eeb:	8b 40 24             	mov    0x24(%eax),%eax
80103eee:	85 c0                	test   %eax,%eax
80103ef0:	74 15                	je     80103f07 <pipewrite+0x4d>
        release(&p->lock);
80103ef2:	8b 45 08             	mov    0x8(%ebp),%eax
80103ef5:	89 04 24             	mov    %eax,(%esp)
80103ef8:	e8 4b 11 00 00       	call   80105048 <release>
        return -1;
80103efd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f02:	e9 9f 00 00 00       	jmp    80103fa6 <pipewrite+0xec>
      }
      wakeup(&p->nread);
80103f07:	8b 45 08             	mov    0x8(%ebp),%eax
80103f0a:	05 34 02 00 00       	add    $0x234,%eax
80103f0f:	89 04 24             	mov    %eax,(%esp)
80103f12:	e8 b9 0b 00 00       	call   80104ad0 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103f17:	8b 45 08             	mov    0x8(%ebp),%eax
80103f1a:	8b 55 08             	mov    0x8(%ebp),%edx
80103f1d:	81 c2 38 02 00 00    	add    $0x238,%edx
80103f23:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f27:	89 14 24             	mov    %edx,(%esp)
80103f2a:	e8 ca 0a 00 00       	call   801049f9 <sleep>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103f2f:	8b 45 08             	mov    0x8(%ebp),%eax
80103f32:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80103f38:	8b 45 08             	mov    0x8(%ebp),%eax
80103f3b:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80103f41:	05 00 02 00 00       	add    $0x200,%eax
80103f46:	39 c2                	cmp    %eax,%edx
80103f48:	74 8f                	je     80103ed9 <pipewrite+0x1f>
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103f4a:	8b 45 08             	mov    0x8(%ebp),%eax
80103f4d:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103f53:	8d 48 01             	lea    0x1(%eax),%ecx
80103f56:	8b 55 08             	mov    0x8(%ebp),%edx
80103f59:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
80103f5f:	25 ff 01 00 00       	and    $0x1ff,%eax
80103f64:	89 c1                	mov    %eax,%ecx
80103f66:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103f69:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f6c:	01 d0                	add    %edx,%eax
80103f6e:	0f b6 10             	movzbl (%eax),%edx
80103f71:	8b 45 08             	mov    0x8(%ebp),%eax
80103f74:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
  for(i = 0; i < n; i++){
80103f78:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103f7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f7f:	3b 45 10             	cmp    0x10(%ebp),%eax
80103f82:	0f 8c 4f ff ff ff    	jl     80103ed7 <pipewrite+0x1d>
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103f88:	8b 45 08             	mov    0x8(%ebp),%eax
80103f8b:	05 34 02 00 00       	add    $0x234,%eax
80103f90:	89 04 24             	mov    %eax,(%esp)
80103f93:	e8 38 0b 00 00       	call   80104ad0 <wakeup>
  release(&p->lock);
80103f98:	8b 45 08             	mov    0x8(%ebp),%eax
80103f9b:	89 04 24             	mov    %eax,(%esp)
80103f9e:	e8 a5 10 00 00       	call   80105048 <release>
  return n;
80103fa3:	8b 45 10             	mov    0x10(%ebp),%eax
}
80103fa6:	c9                   	leave  
80103fa7:	c3                   	ret    

80103fa8 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103fa8:	55                   	push   %ebp
80103fa9:	89 e5                	mov    %esp,%ebp
80103fab:	53                   	push   %ebx
80103fac:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80103faf:	8b 45 08             	mov    0x8(%ebp),%eax
80103fb2:	89 04 24             	mov    %eax,(%esp)
80103fb5:	e8 26 10 00 00       	call   80104fe0 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103fba:	eb 39                	jmp    80103ff5 <piperead+0x4d>
    if(myproc()->killed){
80103fbc:	e8 a0 01 00 00       	call   80104161 <myproc>
80103fc1:	8b 40 24             	mov    0x24(%eax),%eax
80103fc4:	85 c0                	test   %eax,%eax
80103fc6:	74 15                	je     80103fdd <piperead+0x35>
      release(&p->lock);
80103fc8:	8b 45 08             	mov    0x8(%ebp),%eax
80103fcb:	89 04 24             	mov    %eax,(%esp)
80103fce:	e8 75 10 00 00       	call   80105048 <release>
      return -1;
80103fd3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fd8:	e9 b5 00 00 00       	jmp    80104092 <piperead+0xea>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80103fdd:	8b 45 08             	mov    0x8(%ebp),%eax
80103fe0:	8b 55 08             	mov    0x8(%ebp),%edx
80103fe3:	81 c2 34 02 00 00    	add    $0x234,%edx
80103fe9:	89 44 24 04          	mov    %eax,0x4(%esp)
80103fed:	89 14 24             	mov    %edx,(%esp)
80103ff0:	e8 04 0a 00 00       	call   801049f9 <sleep>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103ff5:	8b 45 08             	mov    0x8(%ebp),%eax
80103ff8:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80103ffe:	8b 45 08             	mov    0x8(%ebp),%eax
80104001:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104007:	39 c2                	cmp    %eax,%edx
80104009:	75 0d                	jne    80104018 <piperead+0x70>
8010400b:	8b 45 08             	mov    0x8(%ebp),%eax
8010400e:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104014:	85 c0                	test   %eax,%eax
80104016:	75 a4                	jne    80103fbc <piperead+0x14>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104018:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010401f:	eb 4b                	jmp    8010406c <piperead+0xc4>
    if(p->nread == p->nwrite)
80104021:	8b 45 08             	mov    0x8(%ebp),%eax
80104024:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
8010402a:	8b 45 08             	mov    0x8(%ebp),%eax
8010402d:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104033:	39 c2                	cmp    %eax,%edx
80104035:	75 02                	jne    80104039 <piperead+0x91>
      break;
80104037:	eb 3b                	jmp    80104074 <piperead+0xcc>
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104039:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010403c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010403f:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80104042:	8b 45 08             	mov    0x8(%ebp),%eax
80104045:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010404b:	8d 48 01             	lea    0x1(%eax),%ecx
8010404e:	8b 55 08             	mov    0x8(%ebp),%edx
80104051:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
80104057:	25 ff 01 00 00       	and    $0x1ff,%eax
8010405c:	89 c2                	mov    %eax,%edx
8010405e:	8b 45 08             	mov    0x8(%ebp),%eax
80104061:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
80104066:	88 03                	mov    %al,(%ebx)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104068:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010406c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010406f:	3b 45 10             	cmp    0x10(%ebp),%eax
80104072:	7c ad                	jl     80104021 <piperead+0x79>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104074:	8b 45 08             	mov    0x8(%ebp),%eax
80104077:	05 38 02 00 00       	add    $0x238,%eax
8010407c:	89 04 24             	mov    %eax,(%esp)
8010407f:	e8 4c 0a 00 00       	call   80104ad0 <wakeup>
  release(&p->lock);
80104084:	8b 45 08             	mov    0x8(%ebp),%eax
80104087:	89 04 24             	mov    %eax,(%esp)
8010408a:	e8 b9 0f 00 00       	call   80105048 <release>
  return i;
8010408f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104092:	83 c4 24             	add    $0x24,%esp
80104095:	5b                   	pop    %ebx
80104096:	5d                   	pop    %ebp
80104097:	c3                   	ret    

80104098 <readeflags>:
{
80104098:	55                   	push   %ebp
80104099:	89 e5                	mov    %esp,%ebp
8010409b:	83 ec 10             	sub    $0x10,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010409e:	9c                   	pushf  
8010409f:	58                   	pop    %eax
801040a0:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801040a3:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801040a6:	c9                   	leave  
801040a7:	c3                   	ret    

801040a8 <sti>:
{
801040a8:	55                   	push   %ebp
801040a9:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801040ab:	fb                   	sti    
}
801040ac:	5d                   	pop    %ebp
801040ad:	c3                   	ret    

801040ae <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
801040ae:	55                   	push   %ebp
801040af:	89 e5                	mov    %esp,%ebp
801040b1:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
801040b4:	c7 44 24 04 94 87 10 	movl   $0x80108794,0x4(%esp)
801040bb:	80 
801040bc:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
801040c3:	e8 f7 0e 00 00       	call   80104fbf <initlock>
}
801040c8:	c9                   	leave  
801040c9:	c3                   	ret    

801040ca <cpuid>:

// Must be called with interrupts disabled
int
cpuid() {
801040ca:	55                   	push   %ebp
801040cb:	89 e5                	mov    %esp,%ebp
801040cd:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
801040d0:	e8 16 00 00 00       	call   801040eb <mycpu>
801040d5:	89 c2                	mov    %eax,%edx
801040d7:	b8 00 38 11 80       	mov    $0x80113800,%eax
801040dc:	29 c2                	sub    %eax,%edx
801040de:	89 d0                	mov    %edx,%eax
801040e0:	c1 f8 04             	sar    $0x4,%eax
801040e3:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
801040e9:	c9                   	leave  
801040ea:	c3                   	ret    

801040eb <mycpu>:

// Must be called with interrupts disabled to avoid the caller being
// rescheduled between reading lapicid and running through the loop.
struct cpu*
mycpu(void)
{
801040eb:	55                   	push   %ebp
801040ec:	89 e5                	mov    %esp,%ebp
801040ee:	83 ec 28             	sub    $0x28,%esp
  int apicid, i;
  
  if(readeflags()&FL_IF)
801040f1:	e8 a2 ff ff ff       	call   80104098 <readeflags>
801040f6:	25 00 02 00 00       	and    $0x200,%eax
801040fb:	85 c0                	test   %eax,%eax
801040fd:	74 0c                	je     8010410b <mycpu+0x20>
    panic("mycpu called with interrupts enabled\n");
801040ff:	c7 04 24 9c 87 10 80 	movl   $0x8010879c,(%esp)
80104106:	e8 57 c4 ff ff       	call   80100562 <panic>
  
  apicid = lapicid();
8010410b:	e8 1f ee ff ff       	call   80102f2f <lapicid>
80104110:	89 45 f0             	mov    %eax,-0x10(%ebp)
  // APIC IDs are not guaranteed to be contiguous. Maybe we should have
  // a reverse map, or reserve a register to store &cpus[i].
  for (i = 0; i < ncpu; ++i) {
80104113:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010411a:	eb 2d                	jmp    80104149 <mycpu+0x5e>
    if (cpus[i].apicid == apicid)
8010411c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010411f:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80104125:	05 00 38 11 80       	add    $0x80113800,%eax
8010412a:	0f b6 00             	movzbl (%eax),%eax
8010412d:	0f b6 c0             	movzbl %al,%eax
80104130:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80104133:	75 10                	jne    80104145 <mycpu+0x5a>
      return &cpus[i];
80104135:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104138:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
8010413e:	05 00 38 11 80       	add    $0x80113800,%eax
80104143:	eb 1a                	jmp    8010415f <mycpu+0x74>
  for (i = 0; i < ncpu; ++i) {
80104145:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104149:	a1 80 3d 11 80       	mov    0x80113d80,%eax
8010414e:	39 45 f4             	cmp    %eax,-0xc(%ebp)
80104151:	7c c9                	jl     8010411c <mycpu+0x31>
  }
  panic("unknown apicid\n");
80104153:	c7 04 24 c2 87 10 80 	movl   $0x801087c2,(%esp)
8010415a:	e8 03 c4 ff ff       	call   80100562 <panic>
}
8010415f:	c9                   	leave  
80104160:	c3                   	ret    

80104161 <myproc>:

// Disable interrupts so that we are not rescheduled
// while reading proc from the cpu structure
struct proc*
myproc(void) {
80104161:	55                   	push   %ebp
80104162:	89 e5                	mov    %esp,%ebp
80104164:	83 ec 18             	sub    $0x18,%esp
  struct cpu *c;
  struct proc *p;
  pushcli();
80104167:	e8 e1 0f 00 00       	call   8010514d <pushcli>
  c = mycpu();
8010416c:	e8 7a ff ff ff       	call   801040eb <mycpu>
80104171:	89 45 f4             	mov    %eax,-0xc(%ebp)
  p = c->proc;
80104174:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104177:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010417d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  popcli();
80104180:	e8 14 10 00 00       	call   80105199 <popcli>
  return p;
80104185:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80104188:	c9                   	leave  
80104189:	c3                   	ret    

8010418a <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
8010418a:	55                   	push   %ebp
8010418b:	89 e5                	mov    %esp,%ebp
8010418d:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104190:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104197:	e8 44 0e 00 00       	call   80104fe0 <acquire>

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010419c:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
801041a3:	eb 53                	jmp    801041f8 <allocproc+0x6e>
    if(p->state == UNUSED)
801041a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041a8:	8b 40 0c             	mov    0xc(%eax),%eax
801041ab:	85 c0                	test   %eax,%eax
801041ad:	75 42                	jne    801041f1 <allocproc+0x67>
      goto found;
801041af:	90                   	nop

  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
801041b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041b3:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
801041ba:	a1 00 b0 10 80       	mov    0x8010b000,%eax
801041bf:	8d 50 01             	lea    0x1(%eax),%edx
801041c2:	89 15 00 b0 10 80    	mov    %edx,0x8010b000
801041c8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041cb:	89 42 10             	mov    %eax,0x10(%edx)

  release(&ptable.lock);
801041ce:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
801041d5:	e8 6e 0e 00 00       	call   80105048 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801041da:	e8 ca e9 ff ff       	call   80102ba9 <kalloc>
801041df:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041e2:	89 42 08             	mov    %eax,0x8(%edx)
801041e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041e8:	8b 40 08             	mov    0x8(%eax),%eax
801041eb:	85 c0                	test   %eax,%eax
801041ed:	75 36                	jne    80104225 <allocproc+0x9b>
801041ef:	eb 23                	jmp    80104214 <allocproc+0x8a>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801041f1:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
801041f8:	81 7d f4 d4 5e 11 80 	cmpl   $0x80115ed4,-0xc(%ebp)
801041ff:	72 a4                	jb     801041a5 <allocproc+0x1b>
  release(&ptable.lock);
80104201:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104208:	e8 3b 0e 00 00       	call   80105048 <release>
  return 0;
8010420d:	b8 00 00 00 00       	mov    $0x0,%eax
80104212:	eb 76                	jmp    8010428a <allocproc+0x100>
    p->state = UNUSED;
80104214:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104217:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
8010421e:	b8 00 00 00 00       	mov    $0x0,%eax
80104223:	eb 65                	jmp    8010428a <allocproc+0x100>
  }
  sp = p->kstack + KSTACKSIZE;
80104225:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104228:	8b 40 08             	mov    0x8(%eax),%eax
8010422b:	05 00 10 00 00       	add    $0x1000,%eax
80104230:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104233:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104237:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010423a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010423d:	89 50 18             	mov    %edx,0x18(%eax)

  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104240:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104244:	ba 31 66 10 80       	mov    $0x80106631,%edx
80104249:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010424c:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
8010424e:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104252:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104255:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104258:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
8010425b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010425e:	8b 40 1c             	mov    0x1c(%eax),%eax
80104261:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104268:	00 
80104269:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104270:	00 
80104271:	89 04 24             	mov    %eax,(%esp)
80104274:	e8 d9 0f 00 00       	call   80105252 <memset>
  p->context->eip = (uint)forkret;
80104279:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010427c:	8b 40 1c             	mov    0x1c(%eax),%eax
8010427f:	ba ba 49 10 80       	mov    $0x801049ba,%edx
80104284:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104287:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010428a:	c9                   	leave  
8010428b:	c3                   	ret    

8010428c <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
8010428c:	55                   	push   %ebp
8010428d:	89 e5                	mov    %esp,%ebp
8010428f:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];

  p = allocproc();
80104292:	e8 f3 fe ff ff       	call   8010418a <allocproc>
80104297:	89 45 f4             	mov    %eax,-0xc(%ebp)
  
  initproc = p;
8010429a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010429d:	a3 20 b6 10 80       	mov    %eax,0x8010b620
  if((p->pgdir = setupkvm()) == 0)
801042a2:	e8 07 39 00 00       	call   80107bae <setupkvm>
801042a7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042aa:	89 42 04             	mov    %eax,0x4(%edx)
801042ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042b0:	8b 40 04             	mov    0x4(%eax),%eax
801042b3:	85 c0                	test   %eax,%eax
801042b5:	75 0c                	jne    801042c3 <userinit+0x37>
    panic("userinit: out of memory?");
801042b7:	c7 04 24 d2 87 10 80 	movl   $0x801087d2,(%esp)
801042be:	e8 9f c2 ff ff       	call   80100562 <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801042c3:	ba 2c 00 00 00       	mov    $0x2c,%edx
801042c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042cb:	8b 40 04             	mov    0x4(%eax),%eax
801042ce:	89 54 24 08          	mov    %edx,0x8(%esp)
801042d2:	c7 44 24 04 c0 b4 10 	movl   $0x8010b4c0,0x4(%esp)
801042d9:	80 
801042da:	89 04 24             	mov    %eax,(%esp)
801042dd:	e8 37 3b 00 00       	call   80107e19 <inituvm>
  p->sz = PGSIZE;
801042e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042e5:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
801042eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042ee:	8b 40 18             	mov    0x18(%eax),%eax
801042f1:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801042f8:	00 
801042f9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104300:	00 
80104301:	89 04 24             	mov    %eax,(%esp)
80104304:	e8 49 0f 00 00       	call   80105252 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104309:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010430c:	8b 40 18             	mov    0x18(%eax),%eax
8010430f:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104315:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104318:	8b 40 18             	mov    0x18(%eax),%eax
8010431b:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104321:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104324:	8b 40 18             	mov    0x18(%eax),%eax
80104327:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010432a:	8b 52 18             	mov    0x18(%edx),%edx
8010432d:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104331:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104335:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104338:	8b 40 18             	mov    0x18(%eax),%eax
8010433b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010433e:	8b 52 18             	mov    0x18(%edx),%edx
80104341:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104345:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104349:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010434c:	8b 40 18             	mov    0x18(%eax),%eax
8010434f:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104356:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104359:	8b 40 18             	mov    0x18(%eax),%eax
8010435c:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104363:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104366:	8b 40 18             	mov    0x18(%eax),%eax
80104369:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  p->ticks = 0; // p1
80104370:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104373:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
8010437a:	00 00 00 
  p->tickets = 10; // p1
8010437d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104380:	c7 40 7c 0a 00 00 00 	movl   $0xa,0x7c(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104387:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010438a:	83 c0 6c             	add    $0x6c,%eax
8010438d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104394:	00 
80104395:	c7 44 24 04 eb 87 10 	movl   $0x801087eb,0x4(%esp)
8010439c:	80 
8010439d:	89 04 24             	mov    %eax,(%esp)
801043a0:	e8 cd 10 00 00       	call   80105472 <safestrcpy>
  p->cwd = namei("/");
801043a5:	c7 04 24 f4 87 10 80 	movl   $0x801087f4,(%esp)
801043ac:	e8 e6 e0 ff ff       	call   80102497 <namei>
801043b1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043b4:	89 42 68             	mov    %eax,0x68(%edx)

  // this assignment to p->state lets other cores
  // run this process. the acquire forces the above
  // writes to be visible, and the lock is also needed
  // because the assignment might not be atomic.
  acquire(&ptable.lock);
801043b7:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
801043be:	e8 1d 0c 00 00       	call   80104fe0 <acquire>

  p->state = RUNNABLE;
801043c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043c6:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  release(&ptable.lock);
801043cd:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
801043d4:	e8 6f 0c 00 00       	call   80105048 <release>
}
801043d9:	c9                   	leave  
801043da:	c3                   	ret    

801043db <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
801043db:	55                   	push   %ebp
801043dc:	89 e5                	mov    %esp,%ebp
801043de:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  struct proc *curproc = myproc();
801043e1:	e8 7b fd ff ff       	call   80104161 <myproc>
801043e6:	89 45 f0             	mov    %eax,-0x10(%ebp)

  sz = curproc->sz;
801043e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043ec:	8b 00                	mov    (%eax),%eax
801043ee:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
801043f1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801043f5:	7e 31                	jle    80104428 <growproc+0x4d>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
801043f7:	8b 55 08             	mov    0x8(%ebp),%edx
801043fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043fd:	01 c2                	add    %eax,%edx
801043ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104402:	8b 40 04             	mov    0x4(%eax),%eax
80104405:	89 54 24 08          	mov    %edx,0x8(%esp)
80104409:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010440c:	89 54 24 04          	mov    %edx,0x4(%esp)
80104410:	89 04 24             	mov    %eax,(%esp)
80104413:	e8 6c 3b 00 00       	call   80107f84 <allocuvm>
80104418:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010441b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010441f:	75 3e                	jne    8010445f <growproc+0x84>
      return -1;
80104421:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104426:	eb 4f                	jmp    80104477 <growproc+0x9c>
  } else if(n < 0){
80104428:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010442c:	79 31                	jns    8010445f <growproc+0x84>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010442e:	8b 55 08             	mov    0x8(%ebp),%edx
80104431:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104434:	01 c2                	add    %eax,%edx
80104436:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104439:	8b 40 04             	mov    0x4(%eax),%eax
8010443c:	89 54 24 08          	mov    %edx,0x8(%esp)
80104440:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104443:	89 54 24 04          	mov    %edx,0x4(%esp)
80104447:	89 04 24             	mov    %eax,(%esp)
8010444a:	e8 4b 3c 00 00       	call   8010809a <deallocuvm>
8010444f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104452:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104456:	75 07                	jne    8010445f <growproc+0x84>
      return -1;
80104458:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010445d:	eb 18                	jmp    80104477 <growproc+0x9c>
  }
  curproc->sz = sz;
8010445f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104462:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104465:	89 10                	mov    %edx,(%eax)
  switchuvm(curproc);
80104467:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010446a:	89 04 24             	mov    %eax,(%esp)
8010446d:	e8 16 38 00 00       	call   80107c88 <switchuvm>
  return 0;
80104472:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104477:	c9                   	leave  
80104478:	c3                   	ret    

80104479 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104479:	55                   	push   %ebp
8010447a:	89 e5                	mov    %esp,%ebp
8010447c:	57                   	push   %edi
8010447d:	56                   	push   %esi
8010447e:	53                   	push   %ebx
8010447f:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;
  struct proc *curproc = myproc();
80104482:	e8 da fc ff ff       	call   80104161 <myproc>
80104487:	89 45 e0             	mov    %eax,-0x20(%ebp)

  // Allocate process.
  if((np = allocproc()) == 0){
8010448a:	e8 fb fc ff ff       	call   8010418a <allocproc>
8010448f:	89 45 dc             	mov    %eax,-0x24(%ebp)
80104492:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80104496:	75 0a                	jne    801044a2 <fork+0x29>
    return -1;
80104498:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010449d:	e9 66 01 00 00       	jmp    80104608 <fork+0x18f>
  }

  // Copy process state from proc.
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
801044a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044a5:	8b 10                	mov    (%eax),%edx
801044a7:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044aa:	8b 40 04             	mov    0x4(%eax),%eax
801044ad:	89 54 24 04          	mov    %edx,0x4(%esp)
801044b1:	89 04 24             	mov    %eax,(%esp)
801044b4:	e8 84 3d 00 00       	call   8010823d <copyuvm>
801044b9:	8b 55 dc             	mov    -0x24(%ebp),%edx
801044bc:	89 42 04             	mov    %eax,0x4(%edx)
801044bf:	8b 45 dc             	mov    -0x24(%ebp),%eax
801044c2:	8b 40 04             	mov    0x4(%eax),%eax
801044c5:	85 c0                	test   %eax,%eax
801044c7:	75 2c                	jne    801044f5 <fork+0x7c>
    kfree(np->kstack);
801044c9:	8b 45 dc             	mov    -0x24(%ebp),%eax
801044cc:	8b 40 08             	mov    0x8(%eax),%eax
801044cf:	89 04 24             	mov    %eax,(%esp)
801044d2:	e8 3c e6 ff ff       	call   80102b13 <kfree>
    np->kstack = 0;
801044d7:	8b 45 dc             	mov    -0x24(%ebp),%eax
801044da:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
801044e1:	8b 45 dc             	mov    -0x24(%ebp),%eax
801044e4:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
801044eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044f0:	e9 13 01 00 00       	jmp    80104608 <fork+0x18f>
  }
  np->sz = curproc->sz;
801044f5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044f8:	8b 10                	mov    (%eax),%edx
801044fa:	8b 45 dc             	mov    -0x24(%ebp),%eax
801044fd:	89 10                	mov    %edx,(%eax)
  np->parent = curproc;
801044ff:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104502:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104505:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *curproc->tf;
80104508:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010450b:	8b 50 18             	mov    0x18(%eax),%edx
8010450e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104511:	8b 40 18             	mov    0x18(%eax),%eax
80104514:	89 c3                	mov    %eax,%ebx
80104516:	b8 13 00 00 00       	mov    $0x13,%eax
8010451b:	89 d7                	mov    %edx,%edi
8010451d:	89 de                	mov    %ebx,%esi
8010451f:	89 c1                	mov    %eax,%ecx
80104521:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104523:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104526:	8b 40 18             	mov    0x18(%eax),%eax
80104529:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104530:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104537:	eb 37                	jmp    80104570 <fork+0xf7>
    if(curproc->ofile[i])
80104539:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010453c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010453f:	83 c2 08             	add    $0x8,%edx
80104542:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104546:	85 c0                	test   %eax,%eax
80104548:	74 22                	je     8010456c <fork+0xf3>
      np->ofile[i] = filedup(curproc->ofile[i]);
8010454a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010454d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104550:	83 c2 08             	add    $0x8,%edx
80104553:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104557:	89 04 24             	mov    %eax,(%esp)
8010455a:	e8 86 ca ff ff       	call   80100fe5 <filedup>
8010455f:	8b 55 dc             	mov    -0x24(%ebp),%edx
80104562:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104565:	83 c1 08             	add    $0x8,%ecx
80104568:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  for(i = 0; i < NOFILE; i++)
8010456c:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104570:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104574:	7e c3                	jle    80104539 <fork+0xc0>
  np->cwd = idup(curproc->cwd);
80104576:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104579:	8b 40 68             	mov    0x68(%eax),%eax
8010457c:	89 04 24             	mov    %eax,(%esp)
8010457f:	e8 a7 d3 ff ff       	call   8010192b <idup>
80104584:	8b 55 dc             	mov    -0x24(%ebp),%edx
80104587:	89 42 68             	mov    %eax,0x68(%edx)

  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
8010458a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010458d:	8d 50 6c             	lea    0x6c(%eax),%edx
80104590:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104593:	83 c0 6c             	add    $0x6c,%eax
80104596:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010459d:	00 
8010459e:	89 54 24 04          	mov    %edx,0x4(%esp)
801045a2:	89 04 24             	mov    %eax,(%esp)
801045a5:	e8 c8 0e 00 00       	call   80105472 <safestrcpy>
  
  np->ticks = 0; // p1
801045aa:	8b 45 dc             	mov    -0x24(%ebp),%eax
801045ad:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
801045b4:	00 00 00 
  if (curproc->tickets > 10) // p1
801045b7:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045ba:	8b 40 7c             	mov    0x7c(%eax),%eax
801045bd:	83 f8 0a             	cmp    $0xa,%eax
801045c0:	7e 0e                	jle    801045d0 <fork+0x157>
  {
    np->tickets = curproc->tickets;
801045c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045c5:	8b 50 7c             	mov    0x7c(%eax),%edx
801045c8:	8b 45 dc             	mov    -0x24(%ebp),%eax
801045cb:	89 50 7c             	mov    %edx,0x7c(%eax)
801045ce:	eb 0a                	jmp    801045da <fork+0x161>
  }
  else
  {
    np->tickets = 10;
801045d0:	8b 45 dc             	mov    -0x24(%ebp),%eax
801045d3:	c7 40 7c 0a 00 00 00 	movl   $0xa,0x7c(%eax)
  }
  
  pid = np->pid;
801045da:	8b 45 dc             	mov    -0x24(%ebp),%eax
801045dd:	8b 40 10             	mov    0x10(%eax),%eax
801045e0:	89 45 d8             	mov    %eax,-0x28(%ebp)

  acquire(&ptable.lock);
801045e3:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
801045ea:	e8 f1 09 00 00       	call   80104fe0 <acquire>

  np->state = RUNNABLE;
801045ef:	8b 45 dc             	mov    -0x24(%ebp),%eax
801045f2:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  release(&ptable.lock);
801045f9:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104600:	e8 43 0a 00 00       	call   80105048 <release>

  return pid;
80104605:	8b 45 d8             	mov    -0x28(%ebp),%eax
}
80104608:	83 c4 2c             	add    $0x2c,%esp
8010460b:	5b                   	pop    %ebx
8010460c:	5e                   	pop    %esi
8010460d:	5f                   	pop    %edi
8010460e:	5d                   	pop    %ebp
8010460f:	c3                   	ret    

80104610 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104610:	55                   	push   %ebp
80104611:	89 e5                	mov    %esp,%ebp
80104613:	83 ec 28             	sub    $0x28,%esp
  struct proc *curproc = myproc();
80104616:	e8 46 fb ff ff       	call   80104161 <myproc>
8010461b:	89 45 ec             	mov    %eax,-0x14(%ebp)
  struct proc *p;
  int fd;

  if(curproc == initproc)
8010461e:	a1 20 b6 10 80       	mov    0x8010b620,%eax
80104623:	39 45 ec             	cmp    %eax,-0x14(%ebp)
80104626:	75 0c                	jne    80104634 <exit+0x24>
    panic("init exiting");
80104628:	c7 04 24 f6 87 10 80 	movl   $0x801087f6,(%esp)
8010462f:	e8 2e bf ff ff       	call   80100562 <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104634:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010463b:	eb 3b                	jmp    80104678 <exit+0x68>
    if(curproc->ofile[fd]){
8010463d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104640:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104643:	83 c2 08             	add    $0x8,%edx
80104646:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010464a:	85 c0                	test   %eax,%eax
8010464c:	74 26                	je     80104674 <exit+0x64>
      fileclose(curproc->ofile[fd]);
8010464e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104651:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104654:	83 c2 08             	add    $0x8,%edx
80104657:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010465b:	89 04 24             	mov    %eax,(%esp)
8010465e:	e8 ca c9 ff ff       	call   8010102d <fileclose>
      curproc->ofile[fd] = 0;
80104663:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104666:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104669:	83 c2 08             	add    $0x8,%edx
8010466c:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104673:	00 
  for(fd = 0; fd < NOFILE; fd++){
80104674:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104678:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
8010467c:	7e bf                	jle    8010463d <exit+0x2d>
    }
  }

  begin_op();
8010467e:	e8 04 ee ff ff       	call   80103487 <begin_op>
  iput(curproc->cwd);
80104683:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104686:	8b 40 68             	mov    0x68(%eax),%eax
80104689:	89 04 24             	mov    %eax,(%esp)
8010468c:	e8 1d d4 ff ff       	call   80101aae <iput>
  end_op();
80104691:	e8 75 ee ff ff       	call   8010350b <end_op>
  curproc->cwd = 0;
80104696:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104699:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
801046a0:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
801046a7:	e8 34 09 00 00       	call   80104fe0 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(curproc->parent);
801046ac:	8b 45 ec             	mov    -0x14(%ebp),%eax
801046af:	8b 40 14             	mov    0x14(%eax),%eax
801046b2:	89 04 24             	mov    %eax,(%esp)
801046b5:	e8 d5 03 00 00       	call   80104a8f <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801046ba:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
801046c1:	eb 36                	jmp    801046f9 <exit+0xe9>
    if(p->parent == curproc){
801046c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046c6:	8b 40 14             	mov    0x14(%eax),%eax
801046c9:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801046cc:	75 24                	jne    801046f2 <exit+0xe2>
      p->parent = initproc;
801046ce:	8b 15 20 b6 10 80    	mov    0x8010b620,%edx
801046d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046d7:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
801046da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046dd:	8b 40 0c             	mov    0xc(%eax),%eax
801046e0:	83 f8 05             	cmp    $0x5,%eax
801046e3:	75 0d                	jne    801046f2 <exit+0xe2>
        wakeup1(initproc);
801046e5:	a1 20 b6 10 80       	mov    0x8010b620,%eax
801046ea:	89 04 24             	mov    %eax,(%esp)
801046ed:	e8 9d 03 00 00       	call   80104a8f <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801046f2:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
801046f9:	81 7d f4 d4 5e 11 80 	cmpl   $0x80115ed4,-0xc(%ebp)
80104700:	72 c1                	jb     801046c3 <exit+0xb3>
    }
  }

  // Jump into the scheduler, never to return.
  curproc->state = ZOMBIE;
80104702:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104705:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
8010470c:	e8 c9 01 00 00       	call   801048da <sched>
  panic("zombie exit");
80104711:	c7 04 24 03 88 10 80 	movl   $0x80108803,(%esp)
80104718:	e8 45 be ff ff       	call   80100562 <panic>

8010471d <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
8010471d:	55                   	push   %ebp
8010471e:	89 e5                	mov    %esp,%ebp
80104720:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;
  struct proc *curproc = myproc();
80104723:	e8 39 fa ff ff       	call   80104161 <myproc>
80104728:	89 45 ec             	mov    %eax,-0x14(%ebp)
  
  acquire(&ptable.lock);
8010472b:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104732:	e8 a9 08 00 00       	call   80104fe0 <acquire>
  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
80104737:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010473e:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
80104745:	e9 98 00 00 00       	jmp    801047e2 <wait+0xc5>
      if(p->parent != curproc)
8010474a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010474d:	8b 40 14             	mov    0x14(%eax),%eax
80104750:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104753:	74 05                	je     8010475a <wait+0x3d>
        continue;
80104755:	e9 81 00 00 00       	jmp    801047db <wait+0xbe>
      havekids = 1;
8010475a:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104761:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104764:	8b 40 0c             	mov    0xc(%eax),%eax
80104767:	83 f8 05             	cmp    $0x5,%eax
8010476a:	75 6f                	jne    801047db <wait+0xbe>
        // Found one.
        pid = p->pid;
8010476c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010476f:	8b 40 10             	mov    0x10(%eax),%eax
80104772:	89 45 e8             	mov    %eax,-0x18(%ebp)
        kfree(p->kstack);
80104775:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104778:	8b 40 08             	mov    0x8(%eax),%eax
8010477b:	89 04 24             	mov    %eax,(%esp)
8010477e:	e8 90 e3 ff ff       	call   80102b13 <kfree>
        p->kstack = 0;
80104783:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104786:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
8010478d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104790:	8b 40 04             	mov    0x4(%eax),%eax
80104793:	89 04 24             	mov    %eax,(%esp)
80104796:	e8 c5 39 00 00       	call   80108160 <freevm>
        p->pid = 0;
8010479b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010479e:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
801047a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047a8:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
801047af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047b2:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
801047b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047b9:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        p->state = UNUSED;
801047c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047c3:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        release(&ptable.lock);
801047ca:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
801047d1:	e8 72 08 00 00       	call   80105048 <release>
        return pid;
801047d6:	8b 45 e8             	mov    -0x18(%ebp),%eax
801047d9:	eb 4f                	jmp    8010482a <wait+0x10d>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801047db:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
801047e2:	81 7d f4 d4 5e 11 80 	cmpl   $0x80115ed4,-0xc(%ebp)
801047e9:	0f 82 5b ff ff ff    	jb     8010474a <wait+0x2d>
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || curproc->killed){
801047ef:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801047f3:	74 0a                	je     801047ff <wait+0xe2>
801047f5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801047f8:	8b 40 24             	mov    0x24(%eax),%eax
801047fb:	85 c0                	test   %eax,%eax
801047fd:	74 13                	je     80104812 <wait+0xf5>
      release(&ptable.lock);
801047ff:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104806:	e8 3d 08 00 00       	call   80105048 <release>
      return -1;
8010480b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104810:	eb 18                	jmp    8010482a <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80104812:	c7 44 24 04 a0 3d 11 	movl   $0x80113da0,0x4(%esp)
80104819:	80 
8010481a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010481d:	89 04 24             	mov    %eax,(%esp)
80104820:	e8 d4 01 00 00       	call   801049f9 <sleep>
  }
80104825:	e9 0d ff ff ff       	jmp    80104737 <wait+0x1a>
}
8010482a:	c9                   	leave  
8010482b:	c3                   	ret    

8010482c <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
8010482c:	55                   	push   %ebp
8010482d:	89 e5                	mov    %esp,%ebp
8010482f:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  struct cpu *c = mycpu();
80104832:	e8 b4 f8 ff ff       	call   801040eb <mycpu>
80104837:	89 45 f0             	mov    %eax,-0x10(%ebp)
  c->proc = 0;
8010483a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010483d:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
80104844:	00 00 00 
  
  for(;;){
    // Enable interrupts on this processor.
    sti();
80104847:	e8 5c f8 ff ff       	call   801040a8 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
8010484c:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104853:	e8 88 07 00 00       	call   80104fe0 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104858:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
8010485f:	eb 5f                	jmp    801048c0 <scheduler+0x94>
      if(p->state != RUNNABLE)
80104861:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104864:	8b 40 0c             	mov    0xc(%eax),%eax
80104867:	83 f8 03             	cmp    $0x3,%eax
8010486a:	74 02                	je     8010486e <scheduler+0x42>
        continue;
8010486c:	eb 4b                	jmp    801048b9 <scheduler+0x8d>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      c->proc = p;
8010486e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104871:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104874:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
      switchuvm(p);
8010487a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010487d:	89 04 24             	mov    %eax,(%esp)
80104880:	e8 03 34 00 00       	call   80107c88 <switchuvm>
      p->state = RUNNING;
80104885:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104888:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)

      swtch(&(c->scheduler), p->context);
8010488f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104892:	8b 40 1c             	mov    0x1c(%eax),%eax
80104895:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104898:	83 c2 04             	add    $0x4,%edx
8010489b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010489f:	89 14 24             	mov    %edx,(%esp)
801048a2:	e8 3c 0c 00 00       	call   801054e3 <swtch>
      switchkvm();
801048a7:	e8 c2 33 00 00       	call   80107c6e <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
801048ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801048af:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801048b6:	00 00 00 
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801048b9:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
801048c0:	81 7d f4 d4 5e 11 80 	cmpl   $0x80115ed4,-0xc(%ebp)
801048c7:	72 98                	jb     80104861 <scheduler+0x35>
    }
    release(&ptable.lock);
801048c9:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
801048d0:	e8 73 07 00 00       	call   80105048 <release>

  }
801048d5:	e9 6d ff ff ff       	jmp    80104847 <scheduler+0x1b>

801048da <sched>:
// be proc->intena and proc->ncli, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
801048da:	55                   	push   %ebp
801048db:	89 e5                	mov    %esp,%ebp
801048dd:	83 ec 28             	sub    $0x28,%esp
  int intena;
  struct proc *p = myproc();
801048e0:	e8 7c f8 ff ff       	call   80104161 <myproc>
801048e5:	89 45 f4             	mov    %eax,-0xc(%ebp)

  if(!holding(&ptable.lock))
801048e8:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
801048ef:	e8 18 08 00 00       	call   8010510c <holding>
801048f4:	85 c0                	test   %eax,%eax
801048f6:	75 0c                	jne    80104904 <sched+0x2a>
    panic("sched ptable.lock");
801048f8:	c7 04 24 0f 88 10 80 	movl   $0x8010880f,(%esp)
801048ff:	e8 5e bc ff ff       	call   80100562 <panic>
  if(mycpu()->ncli != 1)
80104904:	e8 e2 f7 ff ff       	call   801040eb <mycpu>
80104909:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
8010490f:	83 f8 01             	cmp    $0x1,%eax
80104912:	74 0c                	je     80104920 <sched+0x46>
    panic("sched locks");
80104914:	c7 04 24 21 88 10 80 	movl   $0x80108821,(%esp)
8010491b:	e8 42 bc ff ff       	call   80100562 <panic>
  if(p->state == RUNNING)
80104920:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104923:	8b 40 0c             	mov    0xc(%eax),%eax
80104926:	83 f8 04             	cmp    $0x4,%eax
80104929:	75 0c                	jne    80104937 <sched+0x5d>
    panic("sched running");
8010492b:	c7 04 24 2d 88 10 80 	movl   $0x8010882d,(%esp)
80104932:	e8 2b bc ff ff       	call   80100562 <panic>
  if(readeflags()&FL_IF)
80104937:	e8 5c f7 ff ff       	call   80104098 <readeflags>
8010493c:	25 00 02 00 00       	and    $0x200,%eax
80104941:	85 c0                	test   %eax,%eax
80104943:	74 0c                	je     80104951 <sched+0x77>
    panic("sched interruptible");
80104945:	c7 04 24 3b 88 10 80 	movl   $0x8010883b,(%esp)
8010494c:	e8 11 bc ff ff       	call   80100562 <panic>
  intena = mycpu()->intena;
80104951:	e8 95 f7 ff ff       	call   801040eb <mycpu>
80104956:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
8010495c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  swtch(&p->context, mycpu()->scheduler);
8010495f:	e8 87 f7 ff ff       	call   801040eb <mycpu>
80104964:	8b 40 04             	mov    0x4(%eax),%eax
80104967:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010496a:	83 c2 1c             	add    $0x1c,%edx
8010496d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104971:	89 14 24             	mov    %edx,(%esp)
80104974:	e8 6a 0b 00 00       	call   801054e3 <swtch>
  mycpu()->intena = intena;
80104979:	e8 6d f7 ff ff       	call   801040eb <mycpu>
8010497e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104981:	89 90 a8 00 00 00    	mov    %edx,0xa8(%eax)
}
80104987:	c9                   	leave  
80104988:	c3                   	ret    

80104989 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104989:	55                   	push   %ebp
8010498a:	89 e5                	mov    %esp,%ebp
8010498c:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
8010498f:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104996:	e8 45 06 00 00       	call   80104fe0 <acquire>
  myproc()->state = RUNNABLE;
8010499b:	e8 c1 f7 ff ff       	call   80104161 <myproc>
801049a0:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801049a7:	e8 2e ff ff ff       	call   801048da <sched>
  release(&ptable.lock);
801049ac:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
801049b3:	e8 90 06 00 00       	call   80105048 <release>
}
801049b8:	c9                   	leave  
801049b9:	c3                   	ret    

801049ba <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
801049ba:	55                   	push   %ebp
801049bb:	89 e5                	mov    %esp,%ebp
801049bd:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
801049c0:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
801049c7:	e8 7c 06 00 00       	call   80105048 <release>

  if (first) {
801049cc:	a1 04 b0 10 80       	mov    0x8010b004,%eax
801049d1:	85 c0                	test   %eax,%eax
801049d3:	74 22                	je     801049f7 <forkret+0x3d>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot
    // be run from main().
    first = 0;
801049d5:	c7 05 04 b0 10 80 00 	movl   $0x0,0x8010b004
801049dc:	00 00 00 
    iinit(ROOTDEV);
801049df:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801049e6:	e8 05 cc ff ff       	call   801015f0 <iinit>
    initlog(ROOTDEV);
801049eb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801049f2:	e8 8c e8 ff ff       	call   80103283 <initlog>
  }

  // Return to "caller", actually trapret (see allocproc).
}
801049f7:	c9                   	leave  
801049f8:	c3                   	ret    

801049f9 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
801049f9:	55                   	push   %ebp
801049fa:	89 e5                	mov    %esp,%ebp
801049fc:	83 ec 28             	sub    $0x28,%esp
  struct proc *p = myproc();
801049ff:	e8 5d f7 ff ff       	call   80104161 <myproc>
80104a04:	89 45 f4             	mov    %eax,-0xc(%ebp)
  
  if(p == 0)
80104a07:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104a0b:	75 0c                	jne    80104a19 <sleep+0x20>
    panic("sleep");
80104a0d:	c7 04 24 4f 88 10 80 	movl   $0x8010884f,(%esp)
80104a14:	e8 49 bb ff ff       	call   80100562 <panic>

  if(lk == 0)
80104a19:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104a1d:	75 0c                	jne    80104a2b <sleep+0x32>
    panic("sleep without lk");
80104a1f:	c7 04 24 55 88 10 80 	movl   $0x80108855,(%esp)
80104a26:	e8 37 bb ff ff       	call   80100562 <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104a2b:	81 7d 0c a0 3d 11 80 	cmpl   $0x80113da0,0xc(%ebp)
80104a32:	74 17                	je     80104a4b <sleep+0x52>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104a34:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104a3b:	e8 a0 05 00 00       	call   80104fe0 <acquire>
    release(lk);
80104a40:	8b 45 0c             	mov    0xc(%ebp),%eax
80104a43:	89 04 24             	mov    %eax,(%esp)
80104a46:	e8 fd 05 00 00       	call   80105048 <release>
  }
  // Go to sleep.
  p->chan = chan;
80104a4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a4e:	8b 55 08             	mov    0x8(%ebp),%edx
80104a51:	89 50 20             	mov    %edx,0x20(%eax)
  p->state = SLEEPING;
80104a54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a57:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)

  sched();
80104a5e:	e8 77 fe ff ff       	call   801048da <sched>

  // Tidy up.
  p->chan = 0;
80104a63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a66:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104a6d:	81 7d 0c a0 3d 11 80 	cmpl   $0x80113da0,0xc(%ebp)
80104a74:	74 17                	je     80104a8d <sleep+0x94>
    release(&ptable.lock);
80104a76:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104a7d:	e8 c6 05 00 00       	call   80105048 <release>
    acquire(lk);
80104a82:	8b 45 0c             	mov    0xc(%ebp),%eax
80104a85:	89 04 24             	mov    %eax,(%esp)
80104a88:	e8 53 05 00 00       	call   80104fe0 <acquire>
  }
}
80104a8d:	c9                   	leave  
80104a8e:	c3                   	ret    

80104a8f <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104a8f:	55                   	push   %ebp
80104a90:	89 e5                	mov    %esp,%ebp
80104a92:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104a95:	c7 45 fc d4 3d 11 80 	movl   $0x80113dd4,-0x4(%ebp)
80104a9c:	eb 27                	jmp    80104ac5 <wakeup1+0x36>
    if(p->state == SLEEPING && p->chan == chan)
80104a9e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104aa1:	8b 40 0c             	mov    0xc(%eax),%eax
80104aa4:	83 f8 02             	cmp    $0x2,%eax
80104aa7:	75 15                	jne    80104abe <wakeup1+0x2f>
80104aa9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104aac:	8b 40 20             	mov    0x20(%eax),%eax
80104aaf:	3b 45 08             	cmp    0x8(%ebp),%eax
80104ab2:	75 0a                	jne    80104abe <wakeup1+0x2f>
      p->state = RUNNABLE;
80104ab4:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104ab7:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104abe:	81 45 fc 84 00 00 00 	addl   $0x84,-0x4(%ebp)
80104ac5:	81 7d fc d4 5e 11 80 	cmpl   $0x80115ed4,-0x4(%ebp)
80104acc:	72 d0                	jb     80104a9e <wakeup1+0xf>
}
80104ace:	c9                   	leave  
80104acf:	c3                   	ret    

80104ad0 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104ad0:	55                   	push   %ebp
80104ad1:	89 e5                	mov    %esp,%ebp
80104ad3:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104ad6:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104add:	e8 fe 04 00 00       	call   80104fe0 <acquire>
  wakeup1(chan);
80104ae2:	8b 45 08             	mov    0x8(%ebp),%eax
80104ae5:	89 04 24             	mov    %eax,(%esp)
80104ae8:	e8 a2 ff ff ff       	call   80104a8f <wakeup1>
  release(&ptable.lock);
80104aed:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104af4:	e8 4f 05 00 00       	call   80105048 <release>
}
80104af9:	c9                   	leave  
80104afa:	c3                   	ret    

80104afb <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104afb:	55                   	push   %ebp
80104afc:	89 e5                	mov    %esp,%ebp
80104afe:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104b01:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104b08:	e8 d3 04 00 00       	call   80104fe0 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b0d:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
80104b14:	eb 44                	jmp    80104b5a <kill+0x5f>
    if(p->pid == pid){
80104b16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b19:	8b 40 10             	mov    0x10(%eax),%eax
80104b1c:	3b 45 08             	cmp    0x8(%ebp),%eax
80104b1f:	75 32                	jne    80104b53 <kill+0x58>
      p->killed = 1;
80104b21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b24:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104b2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b2e:	8b 40 0c             	mov    0xc(%eax),%eax
80104b31:	83 f8 02             	cmp    $0x2,%eax
80104b34:	75 0a                	jne    80104b40 <kill+0x45>
        p->state = RUNNABLE;
80104b36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b39:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104b40:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104b47:	e8 fc 04 00 00       	call   80105048 <release>
      return 0;
80104b4c:	b8 00 00 00 00       	mov    $0x0,%eax
80104b51:	eb 21                	jmp    80104b74 <kill+0x79>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b53:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
80104b5a:	81 7d f4 d4 5e 11 80 	cmpl   $0x80115ed4,-0xc(%ebp)
80104b61:	72 b3                	jb     80104b16 <kill+0x1b>
    }
  }
  release(&ptable.lock);
80104b63:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104b6a:	e8 d9 04 00 00       	call   80105048 <release>
  return -1;
80104b6f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104b74:	c9                   	leave  
80104b75:	c3                   	ret    

80104b76 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104b76:	55                   	push   %ebp
80104b77:	89 e5                	mov    %esp,%ebp
80104b79:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b7c:	c7 45 f0 d4 3d 11 80 	movl   $0x80113dd4,-0x10(%ebp)
80104b83:	e9 d9 00 00 00       	jmp    80104c61 <procdump+0xeb>
    if(p->state == UNUSED)
80104b88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b8b:	8b 40 0c             	mov    0xc(%eax),%eax
80104b8e:	85 c0                	test   %eax,%eax
80104b90:	75 05                	jne    80104b97 <procdump+0x21>
      continue;
80104b92:	e9 c3 00 00 00       	jmp    80104c5a <procdump+0xe4>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104b97:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b9a:	8b 40 0c             	mov    0xc(%eax),%eax
80104b9d:	83 f8 05             	cmp    $0x5,%eax
80104ba0:	77 23                	ja     80104bc5 <procdump+0x4f>
80104ba2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ba5:	8b 40 0c             	mov    0xc(%eax),%eax
80104ba8:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104baf:	85 c0                	test   %eax,%eax
80104bb1:	74 12                	je     80104bc5 <procdump+0x4f>
      state = states[p->state];
80104bb3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bb6:	8b 40 0c             	mov    0xc(%eax),%eax
80104bb9:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104bc0:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104bc3:	eb 07                	jmp    80104bcc <procdump+0x56>
    else
      state = "???";
80104bc5:	c7 45 ec 66 88 10 80 	movl   $0x80108866,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104bcc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bcf:	8d 50 6c             	lea    0x6c(%eax),%edx
80104bd2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bd5:	8b 40 10             	mov    0x10(%eax),%eax
80104bd8:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104bdc:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104bdf:	89 54 24 08          	mov    %edx,0x8(%esp)
80104be3:	89 44 24 04          	mov    %eax,0x4(%esp)
80104be7:	c7 04 24 6a 88 10 80 	movl   $0x8010886a,(%esp)
80104bee:	e8 d5 b7 ff ff       	call   801003c8 <cprintf>
    if(p->state == SLEEPING){
80104bf3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bf6:	8b 40 0c             	mov    0xc(%eax),%eax
80104bf9:	83 f8 02             	cmp    $0x2,%eax
80104bfc:	75 50                	jne    80104c4e <procdump+0xd8>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104bfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c01:	8b 40 1c             	mov    0x1c(%eax),%eax
80104c04:	8b 40 0c             	mov    0xc(%eax),%eax
80104c07:	83 c0 08             	add    $0x8,%eax
80104c0a:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104c0d:	89 54 24 04          	mov    %edx,0x4(%esp)
80104c11:	89 04 24             	mov    %eax,(%esp)
80104c14:	e8 7a 04 00 00       	call   80105093 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104c19:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104c20:	eb 1b                	jmp    80104c3d <procdump+0xc7>
        cprintf(" %p", pc[i]);
80104c22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c25:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104c29:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c2d:	c7 04 24 73 88 10 80 	movl   $0x80108873,(%esp)
80104c34:	e8 8f b7 ff ff       	call   801003c8 <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80104c39:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104c3d:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104c41:	7f 0b                	jg     80104c4e <procdump+0xd8>
80104c43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c46:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104c4a:	85 c0                	test   %eax,%eax
80104c4c:	75 d4                	jne    80104c22 <procdump+0xac>
    }
    cprintf("\n");
80104c4e:	c7 04 24 77 88 10 80 	movl   $0x80108877,(%esp)
80104c55:	e8 6e b7 ff ff       	call   801003c8 <cprintf>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104c5a:	81 45 f0 84 00 00 00 	addl   $0x84,-0x10(%ebp)
80104c61:	81 7d f0 d4 5e 11 80 	cmpl   $0x80115ed4,-0x10(%ebp)
80104c68:	0f 82 1a ff ff ff    	jb     80104b88 <procdump+0x12>
  }
}
80104c6e:	c9                   	leave  
80104c6f:	c3                   	ret    

80104c70 <fillpstat>:

void
fillpstat(pstatTable *pstat)
{
80104c70:	55                   	push   %ebp
80104c71:	89 e5                	mov    %esp,%ebp
80104c73:	53                   	push   %ebx
80104c74:	83 ec 24             	sub    $0x24,%esp
	struct proc *p;
	int i = 0;
80104c77:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	acquire(&ptable.lock);
80104c7e:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104c85:	e8 56 03 00 00       	call   80104fe0 <acquire>
	
	for (p = ptable.proc; p < &ptable.proc[NPROC]; p++, i++)
80104c8a:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
80104c91:	e9 a7 01 00 00       	jmp    80104e3d <fillpstat+0x1cd>
	{
		if (p->state != UNUSED)
80104c96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c99:	8b 40 0c             	mov    0xc(%eax),%eax
80104c9c:	85 c0                	test   %eax,%eax
80104c9e:	74 1a                	je     80104cba <fillpstat+0x4a>
		{
			(*pstat)[i].inuse = 1;
80104ca0:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104ca3:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104ca6:	89 d0                	mov    %edx,%eax
80104ca8:	c1 e0 03             	shl    $0x3,%eax
80104cab:	01 d0                	add    %edx,%eax
80104cad:	c1 e0 02             	shl    $0x2,%eax
80104cb0:	01 c8                	add    %ecx,%eax
80104cb2:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
80104cb8:	eb 18                	jmp    80104cd2 <fillpstat+0x62>
		}
		else
		{
			(*pstat)[i].inuse = 0;
80104cba:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104cbd:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104cc0:	89 d0                	mov    %edx,%eax
80104cc2:	c1 e0 03             	shl    $0x3,%eax
80104cc5:	01 d0                	add    %edx,%eax
80104cc7:	c1 e0 02             	shl    $0x2,%eax
80104cca:	01 c8                	add    %ecx,%eax
80104ccc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		}
		
		(*pstat)[i].tickets = p->tickets;
80104cd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cd5:	8b 48 7c             	mov    0x7c(%eax),%ecx
80104cd8:	8b 5d 08             	mov    0x8(%ebp),%ebx
80104cdb:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104cde:	89 d0                	mov    %edx,%eax
80104ce0:	c1 e0 03             	shl    $0x3,%eax
80104ce3:	01 d0                	add    %edx,%eax
80104ce5:	c1 e0 02             	shl    $0x2,%eax
80104ce8:	01 d8                	add    %ebx,%eax
80104cea:	83 c0 04             	add    $0x4,%eax
80104ced:	89 08                	mov    %ecx,(%eax)
		(*pstat)[i].ticks = p->ticks;
80104cef:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cf2:	8b 88 80 00 00 00    	mov    0x80(%eax),%ecx
80104cf8:	8b 5d 08             	mov    0x8(%ebp),%ebx
80104cfb:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104cfe:	89 d0                	mov    %edx,%eax
80104d00:	c1 e0 03             	shl    $0x3,%eax
80104d03:	01 d0                	add    %edx,%eax
80104d05:	c1 e0 02             	shl    $0x2,%eax
80104d08:	01 d8                	add    %ebx,%eax
80104d0a:	83 c0 0c             	add    $0xc,%eax
80104d0d:	89 08                	mov    %ecx,(%eax)
		(*pstat)[i].pid = p->pid;
80104d0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d12:	8b 48 10             	mov    0x10(%eax),%ecx
80104d15:	8b 5d 08             	mov    0x8(%ebp),%ebx
80104d18:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d1b:	89 d0                	mov    %edx,%eax
80104d1d:	c1 e0 03             	shl    $0x3,%eax
80104d20:	01 d0                	add    %edx,%eax
80104d22:	c1 e0 02             	shl    $0x2,%eax
80104d25:	01 d8                	add    %ebx,%eax
80104d27:	83 c0 08             	add    $0x8,%eax
80104d2a:	89 08                	mov    %ecx,(%eax)
		safestrcpy((*pstat)[i].name, p->name, sizeof(p->name));
80104d2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d2f:	8d 48 6c             	lea    0x6c(%eax),%ecx
80104d32:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d35:	89 d0                	mov    %edx,%eax
80104d37:	c1 e0 03             	shl    $0x3,%eax
80104d3a:	01 d0                	add    %edx,%eax
80104d3c:	c1 e0 02             	shl    $0x2,%eax
80104d3f:	8d 50 10             	lea    0x10(%eax),%edx
80104d42:	8b 45 08             	mov    0x8(%ebp),%eax
80104d45:	01 d0                	add    %edx,%eax
80104d47:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104d4e:	00 
80104d4f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80104d53:	89 04 24             	mov    %eax,(%esp)
80104d56:	e8 17 07 00 00       	call   80105472 <safestrcpy>

		if (p->state == EMBRYO)
80104d5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d5e:	8b 40 0c             	mov    0xc(%eax),%eax
80104d61:	83 f8 01             	cmp    $0x1,%eax
80104d64:	75 1d                	jne    80104d83 <fillpstat+0x113>
		{
			(*pstat)[i].state = 'E';
80104d66:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104d69:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d6c:	89 d0                	mov    %edx,%eax
80104d6e:	c1 e0 03             	shl    $0x3,%eax
80104d71:	01 d0                	add    %edx,%eax
80104d73:	c1 e0 02             	shl    $0x2,%eax
80104d76:	01 c8                	add    %ecx,%eax
80104d78:	83 c0 20             	add    $0x20,%eax
80104d7b:	c6 00 45             	movb   $0x45,(%eax)
80104d7e:	e9 af 00 00 00       	jmp    80104e32 <fillpstat+0x1c2>
		}
		else if (p->state == RUNNING)
80104d83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d86:	8b 40 0c             	mov    0xc(%eax),%eax
80104d89:	83 f8 04             	cmp    $0x4,%eax
80104d8c:	75 1d                	jne    80104dab <fillpstat+0x13b>
		{
			(*pstat)[i].state = 'R';
80104d8e:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104d91:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d94:	89 d0                	mov    %edx,%eax
80104d96:	c1 e0 03             	shl    $0x3,%eax
80104d99:	01 d0                	add    %edx,%eax
80104d9b:	c1 e0 02             	shl    $0x2,%eax
80104d9e:	01 c8                	add    %ecx,%eax
80104da0:	83 c0 20             	add    $0x20,%eax
80104da3:	c6 00 52             	movb   $0x52,(%eax)
80104da6:	e9 87 00 00 00       	jmp    80104e32 <fillpstat+0x1c2>
		}
		else if (p->state == RUNNABLE)
80104dab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dae:	8b 40 0c             	mov    0xc(%eax),%eax
80104db1:	83 f8 03             	cmp    $0x3,%eax
80104db4:	75 1a                	jne    80104dd0 <fillpstat+0x160>
		{
			(*pstat)[i].state = 'A';
80104db6:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104db9:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104dbc:	89 d0                	mov    %edx,%eax
80104dbe:	c1 e0 03             	shl    $0x3,%eax
80104dc1:	01 d0                	add    %edx,%eax
80104dc3:	c1 e0 02             	shl    $0x2,%eax
80104dc6:	01 c8                	add    %ecx,%eax
80104dc8:	83 c0 20             	add    $0x20,%eax
80104dcb:	c6 00 41             	movb   $0x41,(%eax)
80104dce:	eb 62                	jmp    80104e32 <fillpstat+0x1c2>
		}
		else if (p->state == SLEEPING)
80104dd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dd3:	8b 40 0c             	mov    0xc(%eax),%eax
80104dd6:	83 f8 02             	cmp    $0x2,%eax
80104dd9:	75 1a                	jne    80104df5 <fillpstat+0x185>
		{
			(*pstat)[i].state = 'S';
80104ddb:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104dde:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104de1:	89 d0                	mov    %edx,%eax
80104de3:	c1 e0 03             	shl    $0x3,%eax
80104de6:	01 d0                	add    %edx,%eax
80104de8:	c1 e0 02             	shl    $0x2,%eax
80104deb:	01 c8                	add    %ecx,%eax
80104ded:	83 c0 20             	add    $0x20,%eax
80104df0:	c6 00 53             	movb   $0x53,(%eax)
80104df3:	eb 3d                	jmp    80104e32 <fillpstat+0x1c2>
		}
		else if (p->state == ZOMBIE)
80104df5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104df8:	8b 40 0c             	mov    0xc(%eax),%eax
80104dfb:	83 f8 05             	cmp    $0x5,%eax
80104dfe:	75 1a                	jne    80104e1a <fillpstat+0x1aa>
		{
			(*pstat)[i].state = 'Z';
80104e00:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e03:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e06:	89 d0                	mov    %edx,%eax
80104e08:	c1 e0 03             	shl    $0x3,%eax
80104e0b:	01 d0                	add    %edx,%eax
80104e0d:	c1 e0 02             	shl    $0x2,%eax
80104e10:	01 c8                	add    %ecx,%eax
80104e12:	83 c0 20             	add    $0x20,%eax
80104e15:	c6 00 5a             	movb   $0x5a,(%eax)
80104e18:	eb 18                	jmp    80104e32 <fillpstat+0x1c2>
		}
		else
		{
			(*pstat)[i].state = '?';	
80104e1a:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e1d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e20:	89 d0                	mov    %edx,%eax
80104e22:	c1 e0 03             	shl    $0x3,%eax
80104e25:	01 d0                	add    %edx,%eax
80104e27:	c1 e0 02             	shl    $0x2,%eax
80104e2a:	01 c8                	add    %ecx,%eax
80104e2c:	83 c0 20             	add    $0x20,%eax
80104e2f:	c6 00 3f             	movb   $0x3f,(%eax)
	for (p = ptable.proc; p < &ptable.proc[NPROC]; p++, i++)
80104e32:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
80104e39:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104e3d:	81 7d f4 d4 5e 11 80 	cmpl   $0x80115ed4,-0xc(%ebp)
80104e44:	0f 82 4c fe ff ff    	jb     80104c96 <fillpstat+0x26>
		}
	}
	release(&ptable.lock);
80104e4a:	c7 04 24 a0 3d 11 80 	movl   $0x80113da0,(%esp)
80104e51:	e8 f2 01 00 00       	call   80105048 <release>
}
80104e56:	83 c4 24             	add    $0x24,%esp
80104e59:	5b                   	pop    %ebx
80104e5a:	5d                   	pop    %ebp
80104e5b:	c3                   	ret    

80104e5c <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80104e5c:	55                   	push   %ebp
80104e5d:	89 e5                	mov    %esp,%ebp
80104e5f:	83 ec 18             	sub    $0x18,%esp
  initlock(&lk->lk, "sleep lock");
80104e62:	8b 45 08             	mov    0x8(%ebp),%eax
80104e65:	83 c0 04             	add    $0x4,%eax
80104e68:	c7 44 24 04 a3 88 10 	movl   $0x801088a3,0x4(%esp)
80104e6f:	80 
80104e70:	89 04 24             	mov    %eax,(%esp)
80104e73:	e8 47 01 00 00       	call   80104fbf <initlock>
  lk->name = name;
80104e78:	8b 45 08             	mov    0x8(%ebp),%eax
80104e7b:	8b 55 0c             	mov    0xc(%ebp),%edx
80104e7e:	89 50 38             	mov    %edx,0x38(%eax)
  lk->locked = 0;
80104e81:	8b 45 08             	mov    0x8(%ebp),%eax
80104e84:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->pid = 0;
80104e8a:	8b 45 08             	mov    0x8(%ebp),%eax
80104e8d:	c7 40 3c 00 00 00 00 	movl   $0x0,0x3c(%eax)
}
80104e94:	c9                   	leave  
80104e95:	c3                   	ret    

80104e96 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80104e96:	55                   	push   %ebp
80104e97:	89 e5                	mov    %esp,%ebp
80104e99:	83 ec 18             	sub    $0x18,%esp
  acquire(&lk->lk);
80104e9c:	8b 45 08             	mov    0x8(%ebp),%eax
80104e9f:	83 c0 04             	add    $0x4,%eax
80104ea2:	89 04 24             	mov    %eax,(%esp)
80104ea5:	e8 36 01 00 00       	call   80104fe0 <acquire>
  while (lk->locked) {
80104eaa:	eb 15                	jmp    80104ec1 <acquiresleep+0x2b>
    sleep(lk, &lk->lk);
80104eac:	8b 45 08             	mov    0x8(%ebp),%eax
80104eaf:	83 c0 04             	add    $0x4,%eax
80104eb2:	89 44 24 04          	mov    %eax,0x4(%esp)
80104eb6:	8b 45 08             	mov    0x8(%ebp),%eax
80104eb9:	89 04 24             	mov    %eax,(%esp)
80104ebc:	e8 38 fb ff ff       	call   801049f9 <sleep>
  while (lk->locked) {
80104ec1:	8b 45 08             	mov    0x8(%ebp),%eax
80104ec4:	8b 00                	mov    (%eax),%eax
80104ec6:	85 c0                	test   %eax,%eax
80104ec8:	75 e2                	jne    80104eac <acquiresleep+0x16>
  }
  lk->locked = 1;
80104eca:	8b 45 08             	mov    0x8(%ebp),%eax
80104ecd:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  lk->pid = myproc()->pid;
80104ed3:	e8 89 f2 ff ff       	call   80104161 <myproc>
80104ed8:	8b 50 10             	mov    0x10(%eax),%edx
80104edb:	8b 45 08             	mov    0x8(%ebp),%eax
80104ede:	89 50 3c             	mov    %edx,0x3c(%eax)
  release(&lk->lk);
80104ee1:	8b 45 08             	mov    0x8(%ebp),%eax
80104ee4:	83 c0 04             	add    $0x4,%eax
80104ee7:	89 04 24             	mov    %eax,(%esp)
80104eea:	e8 59 01 00 00       	call   80105048 <release>
}
80104eef:	c9                   	leave  
80104ef0:	c3                   	ret    

80104ef1 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80104ef1:	55                   	push   %ebp
80104ef2:	89 e5                	mov    %esp,%ebp
80104ef4:	83 ec 18             	sub    $0x18,%esp
  acquire(&lk->lk);
80104ef7:	8b 45 08             	mov    0x8(%ebp),%eax
80104efa:	83 c0 04             	add    $0x4,%eax
80104efd:	89 04 24             	mov    %eax,(%esp)
80104f00:	e8 db 00 00 00       	call   80104fe0 <acquire>
  lk->locked = 0;
80104f05:	8b 45 08             	mov    0x8(%ebp),%eax
80104f08:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->pid = 0;
80104f0e:	8b 45 08             	mov    0x8(%ebp),%eax
80104f11:	c7 40 3c 00 00 00 00 	movl   $0x0,0x3c(%eax)
  wakeup(lk);
80104f18:	8b 45 08             	mov    0x8(%ebp),%eax
80104f1b:	89 04 24             	mov    %eax,(%esp)
80104f1e:	e8 ad fb ff ff       	call   80104ad0 <wakeup>
  release(&lk->lk);
80104f23:	8b 45 08             	mov    0x8(%ebp),%eax
80104f26:	83 c0 04             	add    $0x4,%eax
80104f29:	89 04 24             	mov    %eax,(%esp)
80104f2c:	e8 17 01 00 00       	call   80105048 <release>
}
80104f31:	c9                   	leave  
80104f32:	c3                   	ret    

80104f33 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80104f33:	55                   	push   %ebp
80104f34:	89 e5                	mov    %esp,%ebp
80104f36:	53                   	push   %ebx
80104f37:	83 ec 24             	sub    $0x24,%esp
  int r;
  
  acquire(&lk->lk);
80104f3a:	8b 45 08             	mov    0x8(%ebp),%eax
80104f3d:	83 c0 04             	add    $0x4,%eax
80104f40:	89 04 24             	mov    %eax,(%esp)
80104f43:	e8 98 00 00 00       	call   80104fe0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80104f48:	8b 45 08             	mov    0x8(%ebp),%eax
80104f4b:	8b 00                	mov    (%eax),%eax
80104f4d:	85 c0                	test   %eax,%eax
80104f4f:	74 19                	je     80104f6a <holdingsleep+0x37>
80104f51:	8b 45 08             	mov    0x8(%ebp),%eax
80104f54:	8b 58 3c             	mov    0x3c(%eax),%ebx
80104f57:	e8 05 f2 ff ff       	call   80104161 <myproc>
80104f5c:	8b 40 10             	mov    0x10(%eax),%eax
80104f5f:	39 c3                	cmp    %eax,%ebx
80104f61:	75 07                	jne    80104f6a <holdingsleep+0x37>
80104f63:	b8 01 00 00 00       	mov    $0x1,%eax
80104f68:	eb 05                	jmp    80104f6f <holdingsleep+0x3c>
80104f6a:	b8 00 00 00 00       	mov    $0x0,%eax
80104f6f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&lk->lk);
80104f72:	8b 45 08             	mov    0x8(%ebp),%eax
80104f75:	83 c0 04             	add    $0x4,%eax
80104f78:	89 04 24             	mov    %eax,(%esp)
80104f7b:	e8 c8 00 00 00       	call   80105048 <release>
  return r;
80104f80:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104f83:	83 c4 24             	add    $0x24,%esp
80104f86:	5b                   	pop    %ebx
80104f87:	5d                   	pop    %ebp
80104f88:	c3                   	ret    

80104f89 <readeflags>:
{
80104f89:	55                   	push   %ebp
80104f8a:	89 e5                	mov    %esp,%ebp
80104f8c:	83 ec 10             	sub    $0x10,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104f8f:	9c                   	pushf  
80104f90:	58                   	pop    %eax
80104f91:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104f94:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104f97:	c9                   	leave  
80104f98:	c3                   	ret    

80104f99 <cli>:
{
80104f99:	55                   	push   %ebp
80104f9a:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104f9c:	fa                   	cli    
}
80104f9d:	5d                   	pop    %ebp
80104f9e:	c3                   	ret    

80104f9f <sti>:
{
80104f9f:	55                   	push   %ebp
80104fa0:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104fa2:	fb                   	sti    
}
80104fa3:	5d                   	pop    %ebp
80104fa4:	c3                   	ret    

80104fa5 <xchg>:
{
80104fa5:	55                   	push   %ebp
80104fa6:	89 e5                	mov    %esp,%ebp
80104fa8:	83 ec 10             	sub    $0x10,%esp
  asm volatile("lock; xchgl %0, %1" :
80104fab:	8b 55 08             	mov    0x8(%ebp),%edx
80104fae:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fb1:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104fb4:	f0 87 02             	lock xchg %eax,(%edx)
80104fb7:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return result;
80104fba:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104fbd:	c9                   	leave  
80104fbe:	c3                   	ret    

80104fbf <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104fbf:	55                   	push   %ebp
80104fc0:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104fc2:	8b 45 08             	mov    0x8(%ebp),%eax
80104fc5:	8b 55 0c             	mov    0xc(%ebp),%edx
80104fc8:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104fcb:	8b 45 08             	mov    0x8(%ebp),%eax
80104fce:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104fd4:	8b 45 08             	mov    0x8(%ebp),%eax
80104fd7:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104fde:	5d                   	pop    %ebp
80104fdf:	c3                   	ret    

80104fe0 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104fe0:	55                   	push   %ebp
80104fe1:	89 e5                	mov    %esp,%ebp
80104fe3:	53                   	push   %ebx
80104fe4:	83 ec 14             	sub    $0x14,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104fe7:	e8 61 01 00 00       	call   8010514d <pushcli>
  if(holding(lk))
80104fec:	8b 45 08             	mov    0x8(%ebp),%eax
80104fef:	89 04 24             	mov    %eax,(%esp)
80104ff2:	e8 15 01 00 00       	call   8010510c <holding>
80104ff7:	85 c0                	test   %eax,%eax
80104ff9:	74 0c                	je     80105007 <acquire+0x27>
    panic("acquire");
80104ffb:	c7 04 24 ae 88 10 80 	movl   $0x801088ae,(%esp)
80105002:	e8 5b b5 ff ff       	call   80100562 <panic>

  // The xchg is atomic.
  while(xchg(&lk->locked, 1) != 0)
80105007:	90                   	nop
80105008:	8b 45 08             	mov    0x8(%ebp),%eax
8010500b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105012:	00 
80105013:	89 04 24             	mov    %eax,(%esp)
80105016:	e8 8a ff ff ff       	call   80104fa5 <xchg>
8010501b:	85 c0                	test   %eax,%eax
8010501d:	75 e9                	jne    80105008 <acquire+0x28>
    ;

  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that the critical section's memory
  // references happen after the lock is acquired.
  __sync_synchronize();
8010501f:	0f ae f0             	mfence 

  // Record info about lock acquisition for debugging.
  lk->cpu = mycpu();
80105022:	8b 5d 08             	mov    0x8(%ebp),%ebx
80105025:	e8 c1 f0 ff ff       	call   801040eb <mycpu>
8010502a:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
8010502d:	8b 45 08             	mov    0x8(%ebp),%eax
80105030:	83 c0 0c             	add    $0xc,%eax
80105033:	89 44 24 04          	mov    %eax,0x4(%esp)
80105037:	8d 45 08             	lea    0x8(%ebp),%eax
8010503a:	89 04 24             	mov    %eax,(%esp)
8010503d:	e8 51 00 00 00       	call   80105093 <getcallerpcs>
}
80105042:	83 c4 14             	add    $0x14,%esp
80105045:	5b                   	pop    %ebx
80105046:	5d                   	pop    %ebp
80105047:	c3                   	ret    

80105048 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105048:	55                   	push   %ebp
80105049:	89 e5                	mov    %esp,%ebp
8010504b:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
8010504e:	8b 45 08             	mov    0x8(%ebp),%eax
80105051:	89 04 24             	mov    %eax,(%esp)
80105054:	e8 b3 00 00 00       	call   8010510c <holding>
80105059:	85 c0                	test   %eax,%eax
8010505b:	75 0c                	jne    80105069 <release+0x21>
    panic("release");
8010505d:	c7 04 24 b6 88 10 80 	movl   $0x801088b6,(%esp)
80105064:	e8 f9 b4 ff ff       	call   80100562 <panic>

  lk->pcs[0] = 0;
80105069:	8b 45 08             	mov    0x8(%ebp),%eax
8010506c:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105073:	8b 45 08             	mov    0x8(%ebp),%eax
80105076:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that all the stores in the critical
  // section are visible to other cores before the lock is released.
  // Both the C compiler and the hardware may re-order loads and
  // stores; __sync_synchronize() tells them both not to.
  __sync_synchronize();
8010507d:	0f ae f0             	mfence 

  // Release the lock, equivalent to lk->locked = 0.
  // This code can't use a C assignment, since it might
  // not be atomic. A real OS would use C atomics here.
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80105080:	8b 45 08             	mov    0x8(%ebp),%eax
80105083:	8b 55 08             	mov    0x8(%ebp),%edx
80105086:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  popcli();
8010508c:	e8 08 01 00 00       	call   80105199 <popcli>
}
80105091:	c9                   	leave  
80105092:	c3                   	ret    

80105093 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105093:	55                   	push   %ebp
80105094:	89 e5                	mov    %esp,%ebp
80105096:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80105099:	8b 45 08             	mov    0x8(%ebp),%eax
8010509c:	83 e8 08             	sub    $0x8,%eax
8010509f:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
801050a2:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
801050a9:	eb 38                	jmp    801050e3 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
801050ab:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
801050af:	74 38                	je     801050e9 <getcallerpcs+0x56>
801050b1:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
801050b8:	76 2f                	jbe    801050e9 <getcallerpcs+0x56>
801050ba:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
801050be:	74 29                	je     801050e9 <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
801050c0:	8b 45 f8             	mov    -0x8(%ebp),%eax
801050c3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801050ca:	8b 45 0c             	mov    0xc(%ebp),%eax
801050cd:	01 c2                	add    %eax,%edx
801050cf:	8b 45 fc             	mov    -0x4(%ebp),%eax
801050d2:	8b 40 04             	mov    0x4(%eax),%eax
801050d5:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
801050d7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801050da:	8b 00                	mov    (%eax),%eax
801050dc:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
801050df:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801050e3:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801050e7:	7e c2                	jle    801050ab <getcallerpcs+0x18>
  }
  for(; i < 10; i++)
801050e9:	eb 19                	jmp    80105104 <getcallerpcs+0x71>
    pcs[i] = 0;
801050eb:	8b 45 f8             	mov    -0x8(%ebp),%eax
801050ee:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801050f5:	8b 45 0c             	mov    0xc(%ebp),%eax
801050f8:	01 d0                	add    %edx,%eax
801050fa:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  for(; i < 10; i++)
80105100:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105104:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105108:	7e e1                	jle    801050eb <getcallerpcs+0x58>
}
8010510a:	c9                   	leave  
8010510b:	c3                   	ret    

8010510c <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
8010510c:	55                   	push   %ebp
8010510d:	89 e5                	mov    %esp,%ebp
8010510f:	53                   	push   %ebx
80105110:	83 ec 14             	sub    $0x14,%esp
  int r;
  pushcli();
80105113:	e8 35 00 00 00       	call   8010514d <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80105118:	8b 45 08             	mov    0x8(%ebp),%eax
8010511b:	8b 00                	mov    (%eax),%eax
8010511d:	85 c0                	test   %eax,%eax
8010511f:	74 16                	je     80105137 <holding+0x2b>
80105121:	8b 45 08             	mov    0x8(%ebp),%eax
80105124:	8b 58 08             	mov    0x8(%eax),%ebx
80105127:	e8 bf ef ff ff       	call   801040eb <mycpu>
8010512c:	39 c3                	cmp    %eax,%ebx
8010512e:	75 07                	jne    80105137 <holding+0x2b>
80105130:	b8 01 00 00 00       	mov    $0x1,%eax
80105135:	eb 05                	jmp    8010513c <holding+0x30>
80105137:	b8 00 00 00 00       	mov    $0x0,%eax
8010513c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  popcli();
8010513f:	e8 55 00 00 00       	call   80105199 <popcli>
  return r;
80105144:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105147:	83 c4 14             	add    $0x14,%esp
8010514a:	5b                   	pop    %ebx
8010514b:	5d                   	pop    %ebp
8010514c:	c3                   	ret    

8010514d <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
8010514d:	55                   	push   %ebp
8010514e:	89 e5                	mov    %esp,%ebp
80105150:	83 ec 18             	sub    $0x18,%esp
  int eflags;

  eflags = readeflags();
80105153:	e8 31 fe ff ff       	call   80104f89 <readeflags>
80105158:	89 45 f4             	mov    %eax,-0xc(%ebp)
  cli();
8010515b:	e8 39 fe ff ff       	call   80104f99 <cli>
  if(mycpu()->ncli == 0)
80105160:	e8 86 ef ff ff       	call   801040eb <mycpu>
80105165:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
8010516b:	85 c0                	test   %eax,%eax
8010516d:	75 14                	jne    80105183 <pushcli+0x36>
    mycpu()->intena = eflags & FL_IF;
8010516f:	e8 77 ef ff ff       	call   801040eb <mycpu>
80105174:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105177:	81 e2 00 02 00 00    	and    $0x200,%edx
8010517d:	89 90 a8 00 00 00    	mov    %edx,0xa8(%eax)
  mycpu()->ncli += 1;
80105183:	e8 63 ef ff ff       	call   801040eb <mycpu>
80105188:	8b 90 a4 00 00 00    	mov    0xa4(%eax),%edx
8010518e:	83 c2 01             	add    $0x1,%edx
80105191:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
}
80105197:	c9                   	leave  
80105198:	c3                   	ret    

80105199 <popcli>:

void
popcli(void)
{
80105199:	55                   	push   %ebp
8010519a:	89 e5                	mov    %esp,%ebp
8010519c:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
8010519f:	e8 e5 fd ff ff       	call   80104f89 <readeflags>
801051a4:	25 00 02 00 00       	and    $0x200,%eax
801051a9:	85 c0                	test   %eax,%eax
801051ab:	74 0c                	je     801051b9 <popcli+0x20>
    panic("popcli - interruptible");
801051ad:	c7 04 24 be 88 10 80 	movl   $0x801088be,(%esp)
801051b4:	e8 a9 b3 ff ff       	call   80100562 <panic>
  if(--mycpu()->ncli < 0)
801051b9:	e8 2d ef ff ff       	call   801040eb <mycpu>
801051be:	8b 90 a4 00 00 00    	mov    0xa4(%eax),%edx
801051c4:	83 ea 01             	sub    $0x1,%edx
801051c7:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
801051cd:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
801051d3:	85 c0                	test   %eax,%eax
801051d5:	79 0c                	jns    801051e3 <popcli+0x4a>
    panic("popcli");
801051d7:	c7 04 24 d5 88 10 80 	movl   $0x801088d5,(%esp)
801051de:	e8 7f b3 ff ff       	call   80100562 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
801051e3:	e8 03 ef ff ff       	call   801040eb <mycpu>
801051e8:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
801051ee:	85 c0                	test   %eax,%eax
801051f0:	75 14                	jne    80105206 <popcli+0x6d>
801051f2:	e8 f4 ee ff ff       	call   801040eb <mycpu>
801051f7:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
801051fd:	85 c0                	test   %eax,%eax
801051ff:	74 05                	je     80105206 <popcli+0x6d>
    sti();
80105201:	e8 99 fd ff ff       	call   80104f9f <sti>
}
80105206:	c9                   	leave  
80105207:	c3                   	ret    

80105208 <stosb>:
{
80105208:	55                   	push   %ebp
80105209:	89 e5                	mov    %esp,%ebp
8010520b:	57                   	push   %edi
8010520c:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
8010520d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105210:	8b 55 10             	mov    0x10(%ebp),%edx
80105213:	8b 45 0c             	mov    0xc(%ebp),%eax
80105216:	89 cb                	mov    %ecx,%ebx
80105218:	89 df                	mov    %ebx,%edi
8010521a:	89 d1                	mov    %edx,%ecx
8010521c:	fc                   	cld    
8010521d:	f3 aa                	rep stos %al,%es:(%edi)
8010521f:	89 ca                	mov    %ecx,%edx
80105221:	89 fb                	mov    %edi,%ebx
80105223:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105226:	89 55 10             	mov    %edx,0x10(%ebp)
}
80105229:	5b                   	pop    %ebx
8010522a:	5f                   	pop    %edi
8010522b:	5d                   	pop    %ebp
8010522c:	c3                   	ret    

8010522d <stosl>:
{
8010522d:	55                   	push   %ebp
8010522e:	89 e5                	mov    %esp,%ebp
80105230:	57                   	push   %edi
80105231:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105232:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105235:	8b 55 10             	mov    0x10(%ebp),%edx
80105238:	8b 45 0c             	mov    0xc(%ebp),%eax
8010523b:	89 cb                	mov    %ecx,%ebx
8010523d:	89 df                	mov    %ebx,%edi
8010523f:	89 d1                	mov    %edx,%ecx
80105241:	fc                   	cld    
80105242:	f3 ab                	rep stos %eax,%es:(%edi)
80105244:	89 ca                	mov    %ecx,%edx
80105246:	89 fb                	mov    %edi,%ebx
80105248:	89 5d 08             	mov    %ebx,0x8(%ebp)
8010524b:	89 55 10             	mov    %edx,0x10(%ebp)
}
8010524e:	5b                   	pop    %ebx
8010524f:	5f                   	pop    %edi
80105250:	5d                   	pop    %ebp
80105251:	c3                   	ret    

80105252 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105252:	55                   	push   %ebp
80105253:	89 e5                	mov    %esp,%ebp
80105255:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105258:	8b 45 08             	mov    0x8(%ebp),%eax
8010525b:	83 e0 03             	and    $0x3,%eax
8010525e:	85 c0                	test   %eax,%eax
80105260:	75 49                	jne    801052ab <memset+0x59>
80105262:	8b 45 10             	mov    0x10(%ebp),%eax
80105265:	83 e0 03             	and    $0x3,%eax
80105268:	85 c0                	test   %eax,%eax
8010526a:	75 3f                	jne    801052ab <memset+0x59>
    c &= 0xFF;
8010526c:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105273:	8b 45 10             	mov    0x10(%ebp),%eax
80105276:	c1 e8 02             	shr    $0x2,%eax
80105279:	89 c2                	mov    %eax,%edx
8010527b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010527e:	c1 e0 18             	shl    $0x18,%eax
80105281:	89 c1                	mov    %eax,%ecx
80105283:	8b 45 0c             	mov    0xc(%ebp),%eax
80105286:	c1 e0 10             	shl    $0x10,%eax
80105289:	09 c1                	or     %eax,%ecx
8010528b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010528e:	c1 e0 08             	shl    $0x8,%eax
80105291:	09 c8                	or     %ecx,%eax
80105293:	0b 45 0c             	or     0xc(%ebp),%eax
80105296:	89 54 24 08          	mov    %edx,0x8(%esp)
8010529a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010529e:	8b 45 08             	mov    0x8(%ebp),%eax
801052a1:	89 04 24             	mov    %eax,(%esp)
801052a4:	e8 84 ff ff ff       	call   8010522d <stosl>
801052a9:	eb 19                	jmp    801052c4 <memset+0x72>
  } else
    stosb(dst, c, n);
801052ab:	8b 45 10             	mov    0x10(%ebp),%eax
801052ae:	89 44 24 08          	mov    %eax,0x8(%esp)
801052b2:	8b 45 0c             	mov    0xc(%ebp),%eax
801052b5:	89 44 24 04          	mov    %eax,0x4(%esp)
801052b9:	8b 45 08             	mov    0x8(%ebp),%eax
801052bc:	89 04 24             	mov    %eax,(%esp)
801052bf:	e8 44 ff ff ff       	call   80105208 <stosb>
  return dst;
801052c4:	8b 45 08             	mov    0x8(%ebp),%eax
}
801052c7:	c9                   	leave  
801052c8:	c3                   	ret    

801052c9 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801052c9:	55                   	push   %ebp
801052ca:	89 e5                	mov    %esp,%ebp
801052cc:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;

  s1 = v1;
801052cf:	8b 45 08             	mov    0x8(%ebp),%eax
801052d2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
801052d5:	8b 45 0c             	mov    0xc(%ebp),%eax
801052d8:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
801052db:	eb 30                	jmp    8010530d <memcmp+0x44>
    if(*s1 != *s2)
801052dd:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052e0:	0f b6 10             	movzbl (%eax),%edx
801052e3:	8b 45 f8             	mov    -0x8(%ebp),%eax
801052e6:	0f b6 00             	movzbl (%eax),%eax
801052e9:	38 c2                	cmp    %al,%dl
801052eb:	74 18                	je     80105305 <memcmp+0x3c>
      return *s1 - *s2;
801052ed:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052f0:	0f b6 00             	movzbl (%eax),%eax
801052f3:	0f b6 d0             	movzbl %al,%edx
801052f6:	8b 45 f8             	mov    -0x8(%ebp),%eax
801052f9:	0f b6 00             	movzbl (%eax),%eax
801052fc:	0f b6 c0             	movzbl %al,%eax
801052ff:	29 c2                	sub    %eax,%edx
80105301:	89 d0                	mov    %edx,%eax
80105303:	eb 1a                	jmp    8010531f <memcmp+0x56>
    s1++, s2++;
80105305:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105309:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  while(n-- > 0){
8010530d:	8b 45 10             	mov    0x10(%ebp),%eax
80105310:	8d 50 ff             	lea    -0x1(%eax),%edx
80105313:	89 55 10             	mov    %edx,0x10(%ebp)
80105316:	85 c0                	test   %eax,%eax
80105318:	75 c3                	jne    801052dd <memcmp+0x14>
  }

  return 0;
8010531a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010531f:	c9                   	leave  
80105320:	c3                   	ret    

80105321 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105321:	55                   	push   %ebp
80105322:	89 e5                	mov    %esp,%ebp
80105324:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105327:	8b 45 0c             	mov    0xc(%ebp),%eax
8010532a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
8010532d:	8b 45 08             	mov    0x8(%ebp),%eax
80105330:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105333:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105336:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105339:	73 3d                	jae    80105378 <memmove+0x57>
8010533b:	8b 45 10             	mov    0x10(%ebp),%eax
8010533e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105341:	01 d0                	add    %edx,%eax
80105343:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105346:	76 30                	jbe    80105378 <memmove+0x57>
    s += n;
80105348:	8b 45 10             	mov    0x10(%ebp),%eax
8010534b:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
8010534e:	8b 45 10             	mov    0x10(%ebp),%eax
80105351:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105354:	eb 13                	jmp    80105369 <memmove+0x48>
      *--d = *--s;
80105356:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
8010535a:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010535e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105361:	0f b6 10             	movzbl (%eax),%edx
80105364:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105367:	88 10                	mov    %dl,(%eax)
    while(n-- > 0)
80105369:	8b 45 10             	mov    0x10(%ebp),%eax
8010536c:	8d 50 ff             	lea    -0x1(%eax),%edx
8010536f:	89 55 10             	mov    %edx,0x10(%ebp)
80105372:	85 c0                	test   %eax,%eax
80105374:	75 e0                	jne    80105356 <memmove+0x35>
  if(s < d && s + n > d){
80105376:	eb 26                	jmp    8010539e <memmove+0x7d>
  } else
    while(n-- > 0)
80105378:	eb 17                	jmp    80105391 <memmove+0x70>
      *d++ = *s++;
8010537a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010537d:	8d 50 01             	lea    0x1(%eax),%edx
80105380:	89 55 f8             	mov    %edx,-0x8(%ebp)
80105383:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105386:	8d 4a 01             	lea    0x1(%edx),%ecx
80105389:	89 4d fc             	mov    %ecx,-0x4(%ebp)
8010538c:	0f b6 12             	movzbl (%edx),%edx
8010538f:	88 10                	mov    %dl,(%eax)
    while(n-- > 0)
80105391:	8b 45 10             	mov    0x10(%ebp),%eax
80105394:	8d 50 ff             	lea    -0x1(%eax),%edx
80105397:	89 55 10             	mov    %edx,0x10(%ebp)
8010539a:	85 c0                	test   %eax,%eax
8010539c:	75 dc                	jne    8010537a <memmove+0x59>

  return dst;
8010539e:	8b 45 08             	mov    0x8(%ebp),%eax
}
801053a1:	c9                   	leave  
801053a2:	c3                   	ret    

801053a3 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
801053a3:	55                   	push   %ebp
801053a4:	89 e5                	mov    %esp,%ebp
801053a6:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
801053a9:	8b 45 10             	mov    0x10(%ebp),%eax
801053ac:	89 44 24 08          	mov    %eax,0x8(%esp)
801053b0:	8b 45 0c             	mov    0xc(%ebp),%eax
801053b3:	89 44 24 04          	mov    %eax,0x4(%esp)
801053b7:	8b 45 08             	mov    0x8(%ebp),%eax
801053ba:	89 04 24             	mov    %eax,(%esp)
801053bd:	e8 5f ff ff ff       	call   80105321 <memmove>
}
801053c2:	c9                   	leave  
801053c3:	c3                   	ret    

801053c4 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801053c4:	55                   	push   %ebp
801053c5:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
801053c7:	eb 0c                	jmp    801053d5 <strncmp+0x11>
    n--, p++, q++;
801053c9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801053cd:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801053d1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  while(n > 0 && *p && *p == *q)
801053d5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053d9:	74 1a                	je     801053f5 <strncmp+0x31>
801053db:	8b 45 08             	mov    0x8(%ebp),%eax
801053de:	0f b6 00             	movzbl (%eax),%eax
801053e1:	84 c0                	test   %al,%al
801053e3:	74 10                	je     801053f5 <strncmp+0x31>
801053e5:	8b 45 08             	mov    0x8(%ebp),%eax
801053e8:	0f b6 10             	movzbl (%eax),%edx
801053eb:	8b 45 0c             	mov    0xc(%ebp),%eax
801053ee:	0f b6 00             	movzbl (%eax),%eax
801053f1:	38 c2                	cmp    %al,%dl
801053f3:	74 d4                	je     801053c9 <strncmp+0x5>
  if(n == 0)
801053f5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053f9:	75 07                	jne    80105402 <strncmp+0x3e>
    return 0;
801053fb:	b8 00 00 00 00       	mov    $0x0,%eax
80105400:	eb 16                	jmp    80105418 <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105402:	8b 45 08             	mov    0x8(%ebp),%eax
80105405:	0f b6 00             	movzbl (%eax),%eax
80105408:	0f b6 d0             	movzbl %al,%edx
8010540b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010540e:	0f b6 00             	movzbl (%eax),%eax
80105411:	0f b6 c0             	movzbl %al,%eax
80105414:	29 c2                	sub    %eax,%edx
80105416:	89 d0                	mov    %edx,%eax
}
80105418:	5d                   	pop    %ebp
80105419:	c3                   	ret    

8010541a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
8010541a:	55                   	push   %ebp
8010541b:	89 e5                	mov    %esp,%ebp
8010541d:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
80105420:	8b 45 08             	mov    0x8(%ebp),%eax
80105423:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105426:	90                   	nop
80105427:	8b 45 10             	mov    0x10(%ebp),%eax
8010542a:	8d 50 ff             	lea    -0x1(%eax),%edx
8010542d:	89 55 10             	mov    %edx,0x10(%ebp)
80105430:	85 c0                	test   %eax,%eax
80105432:	7e 1e                	jle    80105452 <strncpy+0x38>
80105434:	8b 45 08             	mov    0x8(%ebp),%eax
80105437:	8d 50 01             	lea    0x1(%eax),%edx
8010543a:	89 55 08             	mov    %edx,0x8(%ebp)
8010543d:	8b 55 0c             	mov    0xc(%ebp),%edx
80105440:	8d 4a 01             	lea    0x1(%edx),%ecx
80105443:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105446:	0f b6 12             	movzbl (%edx),%edx
80105449:	88 10                	mov    %dl,(%eax)
8010544b:	0f b6 00             	movzbl (%eax),%eax
8010544e:	84 c0                	test   %al,%al
80105450:	75 d5                	jne    80105427 <strncpy+0xd>
    ;
  while(n-- > 0)
80105452:	eb 0c                	jmp    80105460 <strncpy+0x46>
    *s++ = 0;
80105454:	8b 45 08             	mov    0x8(%ebp),%eax
80105457:	8d 50 01             	lea    0x1(%eax),%edx
8010545a:	89 55 08             	mov    %edx,0x8(%ebp)
8010545d:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80105460:	8b 45 10             	mov    0x10(%ebp),%eax
80105463:	8d 50 ff             	lea    -0x1(%eax),%edx
80105466:	89 55 10             	mov    %edx,0x10(%ebp)
80105469:	85 c0                	test   %eax,%eax
8010546b:	7f e7                	jg     80105454 <strncpy+0x3a>
  return os;
8010546d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105470:	c9                   	leave  
80105471:	c3                   	ret    

80105472 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105472:	55                   	push   %ebp
80105473:	89 e5                	mov    %esp,%ebp
80105475:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
80105478:	8b 45 08             	mov    0x8(%ebp),%eax
8010547b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
8010547e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105482:	7f 05                	jg     80105489 <safestrcpy+0x17>
    return os;
80105484:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105487:	eb 31                	jmp    801054ba <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105489:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010548d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105491:	7e 1e                	jle    801054b1 <safestrcpy+0x3f>
80105493:	8b 45 08             	mov    0x8(%ebp),%eax
80105496:	8d 50 01             	lea    0x1(%eax),%edx
80105499:	89 55 08             	mov    %edx,0x8(%ebp)
8010549c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010549f:	8d 4a 01             	lea    0x1(%edx),%ecx
801054a2:	89 4d 0c             	mov    %ecx,0xc(%ebp)
801054a5:	0f b6 12             	movzbl (%edx),%edx
801054a8:	88 10                	mov    %dl,(%eax)
801054aa:	0f b6 00             	movzbl (%eax),%eax
801054ad:	84 c0                	test   %al,%al
801054af:	75 d8                	jne    80105489 <safestrcpy+0x17>
    ;
  *s = 0;
801054b1:	8b 45 08             	mov    0x8(%ebp),%eax
801054b4:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801054b7:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801054ba:	c9                   	leave  
801054bb:	c3                   	ret    

801054bc <strlen>:

int
strlen(const char *s)
{
801054bc:	55                   	push   %ebp
801054bd:	89 e5                	mov    %esp,%ebp
801054bf:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801054c2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801054c9:	eb 04                	jmp    801054cf <strlen+0x13>
801054cb:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801054cf:	8b 55 fc             	mov    -0x4(%ebp),%edx
801054d2:	8b 45 08             	mov    0x8(%ebp),%eax
801054d5:	01 d0                	add    %edx,%eax
801054d7:	0f b6 00             	movzbl (%eax),%eax
801054da:	84 c0                	test   %al,%al
801054dc:	75 ed                	jne    801054cb <strlen+0xf>
    ;
  return n;
801054de:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801054e1:	c9                   	leave  
801054e2:	c3                   	ret    

801054e3 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
801054e3:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801054e7:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
801054eb:	55                   	push   %ebp
  pushl %ebx
801054ec:	53                   	push   %ebx
  pushl %esi
801054ed:	56                   	push   %esi
  pushl %edi
801054ee:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801054ef:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801054f1:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
801054f3:	5f                   	pop    %edi
  popl %esi
801054f4:	5e                   	pop    %esi
  popl %ebx
801054f5:	5b                   	pop    %ebx
  popl %ebp
801054f6:	5d                   	pop    %ebp
  ret
801054f7:	c3                   	ret    

801054f8 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
801054f8:	55                   	push   %ebp
801054f9:	89 e5                	mov    %esp,%ebp
801054fb:	83 ec 18             	sub    $0x18,%esp
  struct proc *curproc = myproc();
801054fe:	e8 5e ec ff ff       	call   80104161 <myproc>
80105503:	89 45 f4             	mov    %eax,-0xc(%ebp)

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80105506:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105509:	8b 00                	mov    (%eax),%eax
8010550b:	3b 45 08             	cmp    0x8(%ebp),%eax
8010550e:	76 0f                	jbe    8010551f <fetchint+0x27>
80105510:	8b 45 08             	mov    0x8(%ebp),%eax
80105513:	8d 50 04             	lea    0x4(%eax),%edx
80105516:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105519:	8b 00                	mov    (%eax),%eax
8010551b:	39 c2                	cmp    %eax,%edx
8010551d:	76 07                	jbe    80105526 <fetchint+0x2e>
    return -1;
8010551f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105524:	eb 0f                	jmp    80105535 <fetchint+0x3d>
  *ip = *(int*)(addr);
80105526:	8b 45 08             	mov    0x8(%ebp),%eax
80105529:	8b 10                	mov    (%eax),%edx
8010552b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010552e:	89 10                	mov    %edx,(%eax)
  return 0;
80105530:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105535:	c9                   	leave  
80105536:	c3                   	ret    

80105537 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105537:	55                   	push   %ebp
80105538:	89 e5                	mov    %esp,%ebp
8010553a:	83 ec 18             	sub    $0x18,%esp
  char *s, *ep;
  struct proc *curproc = myproc();
8010553d:	e8 1f ec ff ff       	call   80104161 <myproc>
80105542:	89 45 f0             	mov    %eax,-0x10(%ebp)

  if(addr >= curproc->sz)
80105545:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105548:	8b 00                	mov    (%eax),%eax
8010554a:	3b 45 08             	cmp    0x8(%ebp),%eax
8010554d:	77 07                	ja     80105556 <fetchstr+0x1f>
    return -1;
8010554f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105554:	eb 43                	jmp    80105599 <fetchstr+0x62>
  *pp = (char*)addr;
80105556:	8b 55 08             	mov    0x8(%ebp),%edx
80105559:	8b 45 0c             	mov    0xc(%ebp),%eax
8010555c:	89 10                	mov    %edx,(%eax)
  ep = (char*)curproc->sz;
8010555e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105561:	8b 00                	mov    (%eax),%eax
80105563:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(s = *pp; s < ep; s++){
80105566:	8b 45 0c             	mov    0xc(%ebp),%eax
80105569:	8b 00                	mov    (%eax),%eax
8010556b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010556e:	eb 1c                	jmp    8010558c <fetchstr+0x55>
    if(*s == 0)
80105570:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105573:	0f b6 00             	movzbl (%eax),%eax
80105576:	84 c0                	test   %al,%al
80105578:	75 0e                	jne    80105588 <fetchstr+0x51>
      return s - *pp;
8010557a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010557d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105580:	8b 00                	mov    (%eax),%eax
80105582:	29 c2                	sub    %eax,%edx
80105584:	89 d0                	mov    %edx,%eax
80105586:	eb 11                	jmp    80105599 <fetchstr+0x62>
  for(s = *pp; s < ep; s++){
80105588:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010558c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010558f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80105592:	72 dc                	jb     80105570 <fetchstr+0x39>
  }
  return -1;
80105594:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105599:	c9                   	leave  
8010559a:	c3                   	ret    

8010559b <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010559b:	55                   	push   %ebp
8010559c:	89 e5                	mov    %esp,%ebp
8010559e:	83 ec 18             	sub    $0x18,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
801055a1:	e8 bb eb ff ff       	call   80104161 <myproc>
801055a6:	8b 40 18             	mov    0x18(%eax),%eax
801055a9:	8b 50 44             	mov    0x44(%eax),%edx
801055ac:	8b 45 08             	mov    0x8(%ebp),%eax
801055af:	c1 e0 02             	shl    $0x2,%eax
801055b2:	01 d0                	add    %edx,%eax
801055b4:	8d 50 04             	lea    0x4(%eax),%edx
801055b7:	8b 45 0c             	mov    0xc(%ebp),%eax
801055ba:	89 44 24 04          	mov    %eax,0x4(%esp)
801055be:	89 14 24             	mov    %edx,(%esp)
801055c1:	e8 32 ff ff ff       	call   801054f8 <fetchint>
}
801055c6:	c9                   	leave  
801055c7:	c3                   	ret    

801055c8 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801055c8:	55                   	push   %ebp
801055c9:	89 e5                	mov    %esp,%ebp
801055cb:	83 ec 28             	sub    $0x28,%esp
  int i;
  struct proc *curproc = myproc();
801055ce:	e8 8e eb ff ff       	call   80104161 <myproc>
801055d3:	89 45 f4             	mov    %eax,-0xc(%ebp)
 
  if(argint(n, &i) < 0)
801055d6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801055d9:	89 44 24 04          	mov    %eax,0x4(%esp)
801055dd:	8b 45 08             	mov    0x8(%ebp),%eax
801055e0:	89 04 24             	mov    %eax,(%esp)
801055e3:	e8 b3 ff ff ff       	call   8010559b <argint>
801055e8:	85 c0                	test   %eax,%eax
801055ea:	79 07                	jns    801055f3 <argptr+0x2b>
    return -1;
801055ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055f1:	eb 3d                	jmp    80105630 <argptr+0x68>
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
801055f3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801055f7:	78 21                	js     8010561a <argptr+0x52>
801055f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055fc:	89 c2                	mov    %eax,%edx
801055fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105601:	8b 00                	mov    (%eax),%eax
80105603:	39 c2                	cmp    %eax,%edx
80105605:	73 13                	jae    8010561a <argptr+0x52>
80105607:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010560a:	89 c2                	mov    %eax,%edx
8010560c:	8b 45 10             	mov    0x10(%ebp),%eax
8010560f:	01 c2                	add    %eax,%edx
80105611:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105614:	8b 00                	mov    (%eax),%eax
80105616:	39 c2                	cmp    %eax,%edx
80105618:	76 07                	jbe    80105621 <argptr+0x59>
    return -1;
8010561a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010561f:	eb 0f                	jmp    80105630 <argptr+0x68>
  *pp = (char*)i;
80105621:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105624:	89 c2                	mov    %eax,%edx
80105626:	8b 45 0c             	mov    0xc(%ebp),%eax
80105629:	89 10                	mov    %edx,(%eax)
  return 0;
8010562b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105630:	c9                   	leave  
80105631:	c3                   	ret    

80105632 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105632:	55                   	push   %ebp
80105633:	89 e5                	mov    %esp,%ebp
80105635:	83 ec 28             	sub    $0x28,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105638:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010563b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010563f:	8b 45 08             	mov    0x8(%ebp),%eax
80105642:	89 04 24             	mov    %eax,(%esp)
80105645:	e8 51 ff ff ff       	call   8010559b <argint>
8010564a:	85 c0                	test   %eax,%eax
8010564c:	79 07                	jns    80105655 <argstr+0x23>
    return -1;
8010564e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105653:	eb 12                	jmp    80105667 <argstr+0x35>
  return fetchstr(addr, pp);
80105655:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105658:	8b 55 0c             	mov    0xc(%ebp),%edx
8010565b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010565f:	89 04 24             	mov    %eax,(%esp)
80105662:	e8 d0 fe ff ff       	call   80105537 <fetchstr>
}
80105667:	c9                   	leave  
80105668:	c3                   	ret    

80105669 <syscall>:
[SYS_getpinfo] sys_getpinfo,
};

void
syscall(void)
{
80105669:	55                   	push   %ebp
8010566a:	89 e5                	mov    %esp,%ebp
8010566c:	53                   	push   %ebx
8010566d:	83 ec 24             	sub    $0x24,%esp
  int num;
  struct proc *curproc = myproc();
80105670:	e8 ec ea ff ff       	call   80104161 <myproc>
80105675:	89 45 f4             	mov    %eax,-0xc(%ebp)

  num = curproc->tf->eax;
80105678:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010567b:	8b 40 18             	mov    0x18(%eax),%eax
8010567e:	8b 40 1c             	mov    0x1c(%eax),%eax
80105681:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80105684:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105688:	7e 2d                	jle    801056b7 <syscall+0x4e>
8010568a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010568d:	83 f8 16             	cmp    $0x16,%eax
80105690:	77 25                	ja     801056b7 <syscall+0x4e>
80105692:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105695:	8b 04 85 20 b0 10 80 	mov    -0x7fef4fe0(,%eax,4),%eax
8010569c:	85 c0                	test   %eax,%eax
8010569e:	74 17                	je     801056b7 <syscall+0x4e>
    curproc->tf->eax = syscalls[num]();
801056a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056a3:	8b 58 18             	mov    0x18(%eax),%ebx
801056a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056a9:	8b 04 85 20 b0 10 80 	mov    -0x7fef4fe0(,%eax,4),%eax
801056b0:	ff d0                	call   *%eax
801056b2:	89 43 1c             	mov    %eax,0x1c(%ebx)
801056b5:	eb 34                	jmp    801056eb <syscall+0x82>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
801056b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056ba:	8d 48 6c             	lea    0x6c(%eax),%ecx
    cprintf("%d %s: unknown sys call %d\n",
801056bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056c0:	8b 40 10             	mov    0x10(%eax),%eax
801056c3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801056c6:	89 54 24 0c          	mov    %edx,0xc(%esp)
801056ca:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801056ce:	89 44 24 04          	mov    %eax,0x4(%esp)
801056d2:	c7 04 24 dc 88 10 80 	movl   $0x801088dc,(%esp)
801056d9:	e8 ea ac ff ff       	call   801003c8 <cprintf>
    curproc->tf->eax = -1;
801056de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056e1:	8b 40 18             	mov    0x18(%eax),%eax
801056e4:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
801056eb:	83 c4 24             	add    $0x24,%esp
801056ee:	5b                   	pop    %ebx
801056ef:	5d                   	pop    %ebp
801056f0:	c3                   	ret    

801056f1 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801056f1:	55                   	push   %ebp
801056f2:	89 e5                	mov    %esp,%ebp
801056f4:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801056f7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801056fa:	89 44 24 04          	mov    %eax,0x4(%esp)
801056fe:	8b 45 08             	mov    0x8(%ebp),%eax
80105701:	89 04 24             	mov    %eax,(%esp)
80105704:	e8 92 fe ff ff       	call   8010559b <argint>
80105709:	85 c0                	test   %eax,%eax
8010570b:	79 07                	jns    80105714 <argfd+0x23>
    return -1;
8010570d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105712:	eb 4f                	jmp    80105763 <argfd+0x72>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
80105714:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105717:	85 c0                	test   %eax,%eax
80105719:	78 20                	js     8010573b <argfd+0x4a>
8010571b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010571e:	83 f8 0f             	cmp    $0xf,%eax
80105721:	7f 18                	jg     8010573b <argfd+0x4a>
80105723:	e8 39 ea ff ff       	call   80104161 <myproc>
80105728:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010572b:	83 c2 08             	add    $0x8,%edx
8010572e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105732:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105735:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105739:	75 07                	jne    80105742 <argfd+0x51>
    return -1;
8010573b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105740:	eb 21                	jmp    80105763 <argfd+0x72>
  if(pfd)
80105742:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105746:	74 08                	je     80105750 <argfd+0x5f>
    *pfd = fd;
80105748:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010574b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010574e:	89 10                	mov    %edx,(%eax)
  if(pf)
80105750:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105754:	74 08                	je     8010575e <argfd+0x6d>
    *pf = f;
80105756:	8b 45 10             	mov    0x10(%ebp),%eax
80105759:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010575c:	89 10                	mov    %edx,(%eax)
  return 0;
8010575e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105763:	c9                   	leave  
80105764:	c3                   	ret    

80105765 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105765:	55                   	push   %ebp
80105766:	89 e5                	mov    %esp,%ebp
80105768:	83 ec 18             	sub    $0x18,%esp
  int fd;
  struct proc *curproc = myproc();
8010576b:	e8 f1 e9 ff ff       	call   80104161 <myproc>
80105770:	89 45 f0             	mov    %eax,-0x10(%ebp)

  for(fd = 0; fd < NOFILE; fd++){
80105773:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010577a:	eb 2a                	jmp    801057a6 <fdalloc+0x41>
    if(curproc->ofile[fd] == 0){
8010577c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010577f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105782:	83 c2 08             	add    $0x8,%edx
80105785:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105789:	85 c0                	test   %eax,%eax
8010578b:	75 15                	jne    801057a2 <fdalloc+0x3d>
      curproc->ofile[fd] = f;
8010578d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105790:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105793:	8d 4a 08             	lea    0x8(%edx),%ecx
80105796:	8b 55 08             	mov    0x8(%ebp),%edx
80105799:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
8010579d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057a0:	eb 0f                	jmp    801057b1 <fdalloc+0x4c>
  for(fd = 0; fd < NOFILE; fd++){
801057a2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801057a6:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801057aa:	7e d0                	jle    8010577c <fdalloc+0x17>
    }
  }
  return -1;
801057ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801057b1:	c9                   	leave  
801057b2:	c3                   	ret    

801057b3 <sys_dup>:

int
sys_dup(void)
{
801057b3:	55                   	push   %ebp
801057b4:	89 e5                	mov    %esp,%ebp
801057b6:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
801057b9:	8d 45 f0             	lea    -0x10(%ebp),%eax
801057bc:	89 44 24 08          	mov    %eax,0x8(%esp)
801057c0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801057c7:	00 
801057c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801057cf:	e8 1d ff ff ff       	call   801056f1 <argfd>
801057d4:	85 c0                	test   %eax,%eax
801057d6:	79 07                	jns    801057df <sys_dup+0x2c>
    return -1;
801057d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057dd:	eb 29                	jmp    80105808 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
801057df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057e2:	89 04 24             	mov    %eax,(%esp)
801057e5:	e8 7b ff ff ff       	call   80105765 <fdalloc>
801057ea:	89 45 f4             	mov    %eax,-0xc(%ebp)
801057ed:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801057f1:	79 07                	jns    801057fa <sys_dup+0x47>
    return -1;
801057f3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057f8:	eb 0e                	jmp    80105808 <sys_dup+0x55>
  filedup(f);
801057fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057fd:	89 04 24             	mov    %eax,(%esp)
80105800:	e8 e0 b7 ff ff       	call   80100fe5 <filedup>
  return fd;
80105805:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105808:	c9                   	leave  
80105809:	c3                   	ret    

8010580a <sys_read>:

int
sys_read(void)
{
8010580a:	55                   	push   %ebp
8010580b:	89 e5                	mov    %esp,%ebp
8010580d:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105810:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105813:	89 44 24 08          	mov    %eax,0x8(%esp)
80105817:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010581e:	00 
8010581f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105826:	e8 c6 fe ff ff       	call   801056f1 <argfd>
8010582b:	85 c0                	test   %eax,%eax
8010582d:	78 35                	js     80105864 <sys_read+0x5a>
8010582f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105832:	89 44 24 04          	mov    %eax,0x4(%esp)
80105836:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010583d:	e8 59 fd ff ff       	call   8010559b <argint>
80105842:	85 c0                	test   %eax,%eax
80105844:	78 1e                	js     80105864 <sys_read+0x5a>
80105846:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105849:	89 44 24 08          	mov    %eax,0x8(%esp)
8010584d:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105850:	89 44 24 04          	mov    %eax,0x4(%esp)
80105854:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010585b:	e8 68 fd ff ff       	call   801055c8 <argptr>
80105860:	85 c0                	test   %eax,%eax
80105862:	79 07                	jns    8010586b <sys_read+0x61>
    return -1;
80105864:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105869:	eb 19                	jmp    80105884 <sys_read+0x7a>
  return fileread(f, p, n);
8010586b:	8b 4d f0             	mov    -0x10(%ebp),%ecx
8010586e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105871:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105874:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105878:	89 54 24 04          	mov    %edx,0x4(%esp)
8010587c:	89 04 24             	mov    %eax,(%esp)
8010587f:	e8 ce b8 ff ff       	call   80101152 <fileread>
}
80105884:	c9                   	leave  
80105885:	c3                   	ret    

80105886 <sys_write>:

int
sys_write(void)
{
80105886:	55                   	push   %ebp
80105887:	89 e5                	mov    %esp,%ebp
80105889:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010588c:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010588f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105893:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010589a:	00 
8010589b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801058a2:	e8 4a fe ff ff       	call   801056f1 <argfd>
801058a7:	85 c0                	test   %eax,%eax
801058a9:	78 35                	js     801058e0 <sys_write+0x5a>
801058ab:	8d 45 f0             	lea    -0x10(%ebp),%eax
801058ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801058b2:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801058b9:	e8 dd fc ff ff       	call   8010559b <argint>
801058be:	85 c0                	test   %eax,%eax
801058c0:	78 1e                	js     801058e0 <sys_write+0x5a>
801058c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058c5:	89 44 24 08          	mov    %eax,0x8(%esp)
801058c9:	8d 45 ec             	lea    -0x14(%ebp),%eax
801058cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801058d0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801058d7:	e8 ec fc ff ff       	call   801055c8 <argptr>
801058dc:	85 c0                	test   %eax,%eax
801058de:	79 07                	jns    801058e7 <sys_write+0x61>
    return -1;
801058e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801058e5:	eb 19                	jmp    80105900 <sys_write+0x7a>
  return filewrite(f, p, n);
801058e7:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801058ea:	8b 55 ec             	mov    -0x14(%ebp),%edx
801058ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058f0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801058f4:	89 54 24 04          	mov    %edx,0x4(%esp)
801058f8:	89 04 24             	mov    %eax,(%esp)
801058fb:	e8 0e b9 ff ff       	call   8010120e <filewrite>
}
80105900:	c9                   	leave  
80105901:	c3                   	ret    

80105902 <sys_close>:

int
sys_close(void)
{
80105902:	55                   	push   %ebp
80105903:	89 e5                	mov    %esp,%ebp
80105905:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
80105908:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010590b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010590f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105912:	89 44 24 04          	mov    %eax,0x4(%esp)
80105916:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010591d:	e8 cf fd ff ff       	call   801056f1 <argfd>
80105922:	85 c0                	test   %eax,%eax
80105924:	79 07                	jns    8010592d <sys_close+0x2b>
    return -1;
80105926:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010592b:	eb 23                	jmp    80105950 <sys_close+0x4e>
  myproc()->ofile[fd] = 0;
8010592d:	e8 2f e8 ff ff       	call   80104161 <myproc>
80105932:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105935:	83 c2 08             	add    $0x8,%edx
80105938:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010593f:	00 
  fileclose(f);
80105940:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105943:	89 04 24             	mov    %eax,(%esp)
80105946:	e8 e2 b6 ff ff       	call   8010102d <fileclose>
  return 0;
8010594b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105950:	c9                   	leave  
80105951:	c3                   	ret    

80105952 <sys_fstat>:

int
sys_fstat(void)
{
80105952:	55                   	push   %ebp
80105953:	89 e5                	mov    %esp,%ebp
80105955:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;

  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80105958:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010595b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010595f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105966:	00 
80105967:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010596e:	e8 7e fd ff ff       	call   801056f1 <argfd>
80105973:	85 c0                	test   %eax,%eax
80105975:	78 1f                	js     80105996 <sys_fstat+0x44>
80105977:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
8010597e:	00 
8010597f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105982:	89 44 24 04          	mov    %eax,0x4(%esp)
80105986:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010598d:	e8 36 fc ff ff       	call   801055c8 <argptr>
80105992:	85 c0                	test   %eax,%eax
80105994:	79 07                	jns    8010599d <sys_fstat+0x4b>
    return -1;
80105996:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010599b:	eb 12                	jmp    801059af <sys_fstat+0x5d>
  return filestat(f, st);
8010599d:	8b 55 f0             	mov    -0x10(%ebp),%edx
801059a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059a3:	89 54 24 04          	mov    %edx,0x4(%esp)
801059a7:	89 04 24             	mov    %eax,(%esp)
801059aa:	e8 54 b7 ff ff       	call   80101103 <filestat>
}
801059af:	c9                   	leave  
801059b0:	c3                   	ret    

801059b1 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
801059b1:	55                   	push   %ebp
801059b2:	89 e5                	mov    %esp,%ebp
801059b4:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801059b7:	8d 45 d8             	lea    -0x28(%ebp),%eax
801059ba:	89 44 24 04          	mov    %eax,0x4(%esp)
801059be:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801059c5:	e8 68 fc ff ff       	call   80105632 <argstr>
801059ca:	85 c0                	test   %eax,%eax
801059cc:	78 17                	js     801059e5 <sys_link+0x34>
801059ce:	8d 45 dc             	lea    -0x24(%ebp),%eax
801059d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801059d5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801059dc:	e8 51 fc ff ff       	call   80105632 <argstr>
801059e1:	85 c0                	test   %eax,%eax
801059e3:	79 0a                	jns    801059ef <sys_link+0x3e>
    return -1;
801059e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801059ea:	e9 42 01 00 00       	jmp    80105b31 <sys_link+0x180>

  begin_op();
801059ef:	e8 93 da ff ff       	call   80103487 <begin_op>
  if((ip = namei(old)) == 0){
801059f4:	8b 45 d8             	mov    -0x28(%ebp),%eax
801059f7:	89 04 24             	mov    %eax,(%esp)
801059fa:	e8 98 ca ff ff       	call   80102497 <namei>
801059ff:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105a02:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105a06:	75 0f                	jne    80105a17 <sys_link+0x66>
    end_op();
80105a08:	e8 fe da ff ff       	call   8010350b <end_op>
    return -1;
80105a0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a12:	e9 1a 01 00 00       	jmp    80105b31 <sys_link+0x180>
  }

  ilock(ip);
80105a17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a1a:	89 04 24             	mov    %eax,(%esp)
80105a1d:	e8 3b bf ff ff       	call   8010195d <ilock>
  if(ip->type == T_DIR){
80105a22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a25:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105a29:	66 83 f8 01          	cmp    $0x1,%ax
80105a2d:	75 1a                	jne    80105a49 <sys_link+0x98>
    iunlockput(ip);
80105a2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a32:	89 04 24             	mov    %eax,(%esp)
80105a35:	e8 25 c1 ff ff       	call   80101b5f <iunlockput>
    end_op();
80105a3a:	e8 cc da ff ff       	call   8010350b <end_op>
    return -1;
80105a3f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a44:	e9 e8 00 00 00       	jmp    80105b31 <sys_link+0x180>
  }

  ip->nlink++;
80105a49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a4c:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105a50:	8d 50 01             	lea    0x1(%eax),%edx
80105a53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a56:	66 89 50 56          	mov    %dx,0x56(%eax)
  iupdate(ip);
80105a5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a5d:	89 04 24             	mov    %eax,(%esp)
80105a60:	e8 33 bd ff ff       	call   80101798 <iupdate>
  iunlock(ip);
80105a65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a68:	89 04 24             	mov    %eax,(%esp)
80105a6b:	e8 fa bf ff ff       	call   80101a6a <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80105a70:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105a73:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80105a76:	89 54 24 04          	mov    %edx,0x4(%esp)
80105a7a:	89 04 24             	mov    %eax,(%esp)
80105a7d:	e8 37 ca ff ff       	call   801024b9 <nameiparent>
80105a82:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105a85:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105a89:	75 02                	jne    80105a8d <sys_link+0xdc>
    goto bad;
80105a8b:	eb 68                	jmp    80105af5 <sys_link+0x144>
  ilock(dp);
80105a8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a90:	89 04 24             	mov    %eax,(%esp)
80105a93:	e8 c5 be ff ff       	call   8010195d <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80105a98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a9b:	8b 10                	mov    (%eax),%edx
80105a9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105aa0:	8b 00                	mov    (%eax),%eax
80105aa2:	39 c2                	cmp    %eax,%edx
80105aa4:	75 20                	jne    80105ac6 <sys_link+0x115>
80105aa6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105aa9:	8b 40 04             	mov    0x4(%eax),%eax
80105aac:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ab0:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105ab3:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ab7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105aba:	89 04 24             	mov    %eax,(%esp)
80105abd:	e8 16 c7 ff ff       	call   801021d8 <dirlink>
80105ac2:	85 c0                	test   %eax,%eax
80105ac4:	79 0d                	jns    80105ad3 <sys_link+0x122>
    iunlockput(dp);
80105ac6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ac9:	89 04 24             	mov    %eax,(%esp)
80105acc:	e8 8e c0 ff ff       	call   80101b5f <iunlockput>
    goto bad;
80105ad1:	eb 22                	jmp    80105af5 <sys_link+0x144>
  }
  iunlockput(dp);
80105ad3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ad6:	89 04 24             	mov    %eax,(%esp)
80105ad9:	e8 81 c0 ff ff       	call   80101b5f <iunlockput>
  iput(ip);
80105ade:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ae1:	89 04 24             	mov    %eax,(%esp)
80105ae4:	e8 c5 bf ff ff       	call   80101aae <iput>

  end_op();
80105ae9:	e8 1d da ff ff       	call   8010350b <end_op>

  return 0;
80105aee:	b8 00 00 00 00       	mov    $0x0,%eax
80105af3:	eb 3c                	jmp    80105b31 <sys_link+0x180>

bad:
  ilock(ip);
80105af5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105af8:	89 04 24             	mov    %eax,(%esp)
80105afb:	e8 5d be ff ff       	call   8010195d <ilock>
  ip->nlink--;
80105b00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b03:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105b07:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b0d:	66 89 50 56          	mov    %dx,0x56(%eax)
  iupdate(ip);
80105b11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b14:	89 04 24             	mov    %eax,(%esp)
80105b17:	e8 7c bc ff ff       	call   80101798 <iupdate>
  iunlockput(ip);
80105b1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b1f:	89 04 24             	mov    %eax,(%esp)
80105b22:	e8 38 c0 ff ff       	call   80101b5f <iunlockput>
  end_op();
80105b27:	e8 df d9 ff ff       	call   8010350b <end_op>
  return -1;
80105b2c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105b31:	c9                   	leave  
80105b32:	c3                   	ret    

80105b33 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105b33:	55                   	push   %ebp
80105b34:	89 e5                	mov    %esp,%ebp
80105b36:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105b39:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105b40:	eb 4b                	jmp    80105b8d <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105b42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b45:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105b4c:	00 
80105b4d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b51:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105b54:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b58:	8b 45 08             	mov    0x8(%ebp),%eax
80105b5b:	89 04 24             	mov    %eax,(%esp)
80105b5e:	e8 97 c2 ff ff       	call   80101dfa <readi>
80105b63:	83 f8 10             	cmp    $0x10,%eax
80105b66:	74 0c                	je     80105b74 <isdirempty+0x41>
      panic("isdirempty: readi");
80105b68:	c7 04 24 f8 88 10 80 	movl   $0x801088f8,(%esp)
80105b6f:	e8 ee a9 ff ff       	call   80100562 <panic>
    if(de.inum != 0)
80105b74:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105b78:	66 85 c0             	test   %ax,%ax
80105b7b:	74 07                	je     80105b84 <isdirempty+0x51>
      return 0;
80105b7d:	b8 00 00 00 00       	mov    $0x0,%eax
80105b82:	eb 1b                	jmp    80105b9f <isdirempty+0x6c>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105b84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b87:	83 c0 10             	add    $0x10,%eax
80105b8a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105b8d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105b90:	8b 45 08             	mov    0x8(%ebp),%eax
80105b93:	8b 40 58             	mov    0x58(%eax),%eax
80105b96:	39 c2                	cmp    %eax,%edx
80105b98:	72 a8                	jb     80105b42 <isdirempty+0xf>
  }
  return 1;
80105b9a:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105b9f:	c9                   	leave  
80105ba0:	c3                   	ret    

80105ba1 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105ba1:	55                   	push   %ebp
80105ba2:	89 e5                	mov    %esp,%ebp
80105ba4:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105ba7:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105baa:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bae:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105bb5:	e8 78 fa ff ff       	call   80105632 <argstr>
80105bba:	85 c0                	test   %eax,%eax
80105bbc:	79 0a                	jns    80105bc8 <sys_unlink+0x27>
    return -1;
80105bbe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105bc3:	e9 af 01 00 00       	jmp    80105d77 <sys_unlink+0x1d6>

  begin_op();
80105bc8:	e8 ba d8 ff ff       	call   80103487 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80105bcd:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105bd0:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105bd3:	89 54 24 04          	mov    %edx,0x4(%esp)
80105bd7:	89 04 24             	mov    %eax,(%esp)
80105bda:	e8 da c8 ff ff       	call   801024b9 <nameiparent>
80105bdf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105be2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105be6:	75 0f                	jne    80105bf7 <sys_unlink+0x56>
    end_op();
80105be8:	e8 1e d9 ff ff       	call   8010350b <end_op>
    return -1;
80105bed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105bf2:	e9 80 01 00 00       	jmp    80105d77 <sys_unlink+0x1d6>
  }

  ilock(dp);
80105bf7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bfa:	89 04 24             	mov    %eax,(%esp)
80105bfd:	e8 5b bd ff ff       	call   8010195d <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105c02:	c7 44 24 04 0a 89 10 	movl   $0x8010890a,0x4(%esp)
80105c09:	80 
80105c0a:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105c0d:	89 04 24             	mov    %eax,(%esp)
80105c10:	e8 d8 c4 ff ff       	call   801020ed <namecmp>
80105c15:	85 c0                	test   %eax,%eax
80105c17:	0f 84 45 01 00 00    	je     80105d62 <sys_unlink+0x1c1>
80105c1d:	c7 44 24 04 0c 89 10 	movl   $0x8010890c,0x4(%esp)
80105c24:	80 
80105c25:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105c28:	89 04 24             	mov    %eax,(%esp)
80105c2b:	e8 bd c4 ff ff       	call   801020ed <namecmp>
80105c30:	85 c0                	test   %eax,%eax
80105c32:	0f 84 2a 01 00 00    	je     80105d62 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105c38:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105c3b:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c3f:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105c42:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c49:	89 04 24             	mov    %eax,(%esp)
80105c4c:	e8 be c4 ff ff       	call   8010210f <dirlookup>
80105c51:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105c54:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105c58:	75 05                	jne    80105c5f <sys_unlink+0xbe>
    goto bad;
80105c5a:	e9 03 01 00 00       	jmp    80105d62 <sys_unlink+0x1c1>
  ilock(ip);
80105c5f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c62:	89 04 24             	mov    %eax,(%esp)
80105c65:	e8 f3 bc ff ff       	call   8010195d <ilock>

  if(ip->nlink < 1)
80105c6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c6d:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105c71:	66 85 c0             	test   %ax,%ax
80105c74:	7f 0c                	jg     80105c82 <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
80105c76:	c7 04 24 0f 89 10 80 	movl   $0x8010890f,(%esp)
80105c7d:	e8 e0 a8 ff ff       	call   80100562 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105c82:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c85:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105c89:	66 83 f8 01          	cmp    $0x1,%ax
80105c8d:	75 1f                	jne    80105cae <sys_unlink+0x10d>
80105c8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c92:	89 04 24             	mov    %eax,(%esp)
80105c95:	e8 99 fe ff ff       	call   80105b33 <isdirempty>
80105c9a:	85 c0                	test   %eax,%eax
80105c9c:	75 10                	jne    80105cae <sys_unlink+0x10d>
    iunlockput(ip);
80105c9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ca1:	89 04 24             	mov    %eax,(%esp)
80105ca4:	e8 b6 be ff ff       	call   80101b5f <iunlockput>
    goto bad;
80105ca9:	e9 b4 00 00 00       	jmp    80105d62 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80105cae:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105cb5:	00 
80105cb6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105cbd:	00 
80105cbe:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105cc1:	89 04 24             	mov    %eax,(%esp)
80105cc4:	e8 89 f5 ff ff       	call   80105252 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105cc9:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105ccc:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105cd3:	00 
80105cd4:	89 44 24 08          	mov    %eax,0x8(%esp)
80105cd8:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105cdb:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cdf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ce2:	89 04 24             	mov    %eax,(%esp)
80105ce5:	e8 74 c2 ff ff       	call   80101f5e <writei>
80105cea:	83 f8 10             	cmp    $0x10,%eax
80105ced:	74 0c                	je     80105cfb <sys_unlink+0x15a>
    panic("unlink: writei");
80105cef:	c7 04 24 21 89 10 80 	movl   $0x80108921,(%esp)
80105cf6:	e8 67 a8 ff ff       	call   80100562 <panic>
  if(ip->type == T_DIR){
80105cfb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cfe:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105d02:	66 83 f8 01          	cmp    $0x1,%ax
80105d06:	75 1c                	jne    80105d24 <sys_unlink+0x183>
    dp->nlink--;
80105d08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d0b:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105d0f:	8d 50 ff             	lea    -0x1(%eax),%edx
80105d12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d15:	66 89 50 56          	mov    %dx,0x56(%eax)
    iupdate(dp);
80105d19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d1c:	89 04 24             	mov    %eax,(%esp)
80105d1f:	e8 74 ba ff ff       	call   80101798 <iupdate>
  }
  iunlockput(dp);
80105d24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d27:	89 04 24             	mov    %eax,(%esp)
80105d2a:	e8 30 be ff ff       	call   80101b5f <iunlockput>

  ip->nlink--;
80105d2f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d32:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105d36:	8d 50 ff             	lea    -0x1(%eax),%edx
80105d39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d3c:	66 89 50 56          	mov    %dx,0x56(%eax)
  iupdate(ip);
80105d40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d43:	89 04 24             	mov    %eax,(%esp)
80105d46:	e8 4d ba ff ff       	call   80101798 <iupdate>
  iunlockput(ip);
80105d4b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d4e:	89 04 24             	mov    %eax,(%esp)
80105d51:	e8 09 be ff ff       	call   80101b5f <iunlockput>

  end_op();
80105d56:	e8 b0 d7 ff ff       	call   8010350b <end_op>

  return 0;
80105d5b:	b8 00 00 00 00       	mov    $0x0,%eax
80105d60:	eb 15                	jmp    80105d77 <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
80105d62:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d65:	89 04 24             	mov    %eax,(%esp)
80105d68:	e8 f2 bd ff ff       	call   80101b5f <iunlockput>
  end_op();
80105d6d:	e8 99 d7 ff ff       	call   8010350b <end_op>
  return -1;
80105d72:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105d77:	c9                   	leave  
80105d78:	c3                   	ret    

80105d79 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105d79:	55                   	push   %ebp
80105d7a:	89 e5                	mov    %esp,%ebp
80105d7c:	83 ec 48             	sub    $0x48,%esp
80105d7f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105d82:	8b 55 10             	mov    0x10(%ebp),%edx
80105d85:	8b 45 14             	mov    0x14(%ebp),%eax
80105d88:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105d8c:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105d90:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105d94:	8d 45 de             	lea    -0x22(%ebp),%eax
80105d97:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d9b:	8b 45 08             	mov    0x8(%ebp),%eax
80105d9e:	89 04 24             	mov    %eax,(%esp)
80105da1:	e8 13 c7 ff ff       	call   801024b9 <nameiparent>
80105da6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105da9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105dad:	75 0a                	jne    80105db9 <create+0x40>
    return 0;
80105daf:	b8 00 00 00 00       	mov    $0x0,%eax
80105db4:	e9 7e 01 00 00       	jmp    80105f37 <create+0x1be>
  ilock(dp);
80105db9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dbc:	89 04 24             	mov    %eax,(%esp)
80105dbf:	e8 99 bb ff ff       	call   8010195d <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80105dc4:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105dc7:	89 44 24 08          	mov    %eax,0x8(%esp)
80105dcb:	8d 45 de             	lea    -0x22(%ebp),%eax
80105dce:	89 44 24 04          	mov    %eax,0x4(%esp)
80105dd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dd5:	89 04 24             	mov    %eax,(%esp)
80105dd8:	e8 32 c3 ff ff       	call   8010210f <dirlookup>
80105ddd:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105de0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105de4:	74 47                	je     80105e2d <create+0xb4>
    iunlockput(dp);
80105de6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105de9:	89 04 24             	mov    %eax,(%esp)
80105dec:	e8 6e bd ff ff       	call   80101b5f <iunlockput>
    ilock(ip);
80105df1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105df4:	89 04 24             	mov    %eax,(%esp)
80105df7:	e8 61 bb ff ff       	call   8010195d <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105dfc:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105e01:	75 15                	jne    80105e18 <create+0x9f>
80105e03:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e06:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105e0a:	66 83 f8 02          	cmp    $0x2,%ax
80105e0e:	75 08                	jne    80105e18 <create+0x9f>
      return ip;
80105e10:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e13:	e9 1f 01 00 00       	jmp    80105f37 <create+0x1be>
    iunlockput(ip);
80105e18:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e1b:	89 04 24             	mov    %eax,(%esp)
80105e1e:	e8 3c bd ff ff       	call   80101b5f <iunlockput>
    return 0;
80105e23:	b8 00 00 00 00       	mov    $0x0,%eax
80105e28:	e9 0a 01 00 00       	jmp    80105f37 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105e2d:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105e31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e34:	8b 00                	mov    (%eax),%eax
80105e36:	89 54 24 04          	mov    %edx,0x4(%esp)
80105e3a:	89 04 24             	mov    %eax,(%esp)
80105e3d:	e8 81 b8 ff ff       	call   801016c3 <ialloc>
80105e42:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105e45:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105e49:	75 0c                	jne    80105e57 <create+0xde>
    panic("create: ialloc");
80105e4b:	c7 04 24 30 89 10 80 	movl   $0x80108930,(%esp)
80105e52:	e8 0b a7 ff ff       	call   80100562 <panic>

  ilock(ip);
80105e57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e5a:	89 04 24             	mov    %eax,(%esp)
80105e5d:	e8 fb ba ff ff       	call   8010195d <ilock>
  ip->major = major;
80105e62:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e65:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105e69:	66 89 50 52          	mov    %dx,0x52(%eax)
  ip->minor = minor;
80105e6d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e70:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105e74:	66 89 50 54          	mov    %dx,0x54(%eax)
  ip->nlink = 1;
80105e78:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e7b:	66 c7 40 56 01 00    	movw   $0x1,0x56(%eax)
  iupdate(ip);
80105e81:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e84:	89 04 24             	mov    %eax,(%esp)
80105e87:	e8 0c b9 ff ff       	call   80101798 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105e8c:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105e91:	75 6a                	jne    80105efd <create+0x184>
    dp->nlink++;  // for ".."
80105e93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e96:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105e9a:	8d 50 01             	lea    0x1(%eax),%edx
80105e9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ea0:	66 89 50 56          	mov    %dx,0x56(%eax)
    iupdate(dp);
80105ea4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ea7:	89 04 24             	mov    %eax,(%esp)
80105eaa:	e8 e9 b8 ff ff       	call   80101798 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105eaf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105eb2:	8b 40 04             	mov    0x4(%eax),%eax
80105eb5:	89 44 24 08          	mov    %eax,0x8(%esp)
80105eb9:	c7 44 24 04 0a 89 10 	movl   $0x8010890a,0x4(%esp)
80105ec0:	80 
80105ec1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ec4:	89 04 24             	mov    %eax,(%esp)
80105ec7:	e8 0c c3 ff ff       	call   801021d8 <dirlink>
80105ecc:	85 c0                	test   %eax,%eax
80105ece:	78 21                	js     80105ef1 <create+0x178>
80105ed0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ed3:	8b 40 04             	mov    0x4(%eax),%eax
80105ed6:	89 44 24 08          	mov    %eax,0x8(%esp)
80105eda:	c7 44 24 04 0c 89 10 	movl   $0x8010890c,0x4(%esp)
80105ee1:	80 
80105ee2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ee5:	89 04 24             	mov    %eax,(%esp)
80105ee8:	e8 eb c2 ff ff       	call   801021d8 <dirlink>
80105eed:	85 c0                	test   %eax,%eax
80105eef:	79 0c                	jns    80105efd <create+0x184>
      panic("create dots");
80105ef1:	c7 04 24 3f 89 10 80 	movl   $0x8010893f,(%esp)
80105ef8:	e8 65 a6 ff ff       	call   80100562 <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105efd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f00:	8b 40 04             	mov    0x4(%eax),%eax
80105f03:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f07:	8d 45 de             	lea    -0x22(%ebp),%eax
80105f0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f11:	89 04 24             	mov    %eax,(%esp)
80105f14:	e8 bf c2 ff ff       	call   801021d8 <dirlink>
80105f19:	85 c0                	test   %eax,%eax
80105f1b:	79 0c                	jns    80105f29 <create+0x1b0>
    panic("create: dirlink");
80105f1d:	c7 04 24 4b 89 10 80 	movl   $0x8010894b,(%esp)
80105f24:	e8 39 a6 ff ff       	call   80100562 <panic>

  iunlockput(dp);
80105f29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f2c:	89 04 24             	mov    %eax,(%esp)
80105f2f:	e8 2b bc ff ff       	call   80101b5f <iunlockput>

  return ip;
80105f34:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105f37:	c9                   	leave  
80105f38:	c3                   	ret    

80105f39 <sys_open>:

int
sys_open(void)
{
80105f39:	55                   	push   %ebp
80105f3a:	89 e5                	mov    %esp,%ebp
80105f3c:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105f3f:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105f42:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f46:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f4d:	e8 e0 f6 ff ff       	call   80105632 <argstr>
80105f52:	85 c0                	test   %eax,%eax
80105f54:	78 17                	js     80105f6d <sys_open+0x34>
80105f56:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105f59:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f5d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105f64:	e8 32 f6 ff ff       	call   8010559b <argint>
80105f69:	85 c0                	test   %eax,%eax
80105f6b:	79 0a                	jns    80105f77 <sys_open+0x3e>
    return -1;
80105f6d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f72:	e9 5c 01 00 00       	jmp    801060d3 <sys_open+0x19a>

  begin_op();
80105f77:	e8 0b d5 ff ff       	call   80103487 <begin_op>

  if(omode & O_CREATE){
80105f7c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f7f:	25 00 02 00 00       	and    $0x200,%eax
80105f84:	85 c0                	test   %eax,%eax
80105f86:	74 3b                	je     80105fc3 <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80105f88:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105f8b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105f92:	00 
80105f93:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105f9a:	00 
80105f9b:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105fa2:	00 
80105fa3:	89 04 24             	mov    %eax,(%esp)
80105fa6:	e8 ce fd ff ff       	call   80105d79 <create>
80105fab:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80105fae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105fb2:	75 6b                	jne    8010601f <sys_open+0xe6>
      end_op();
80105fb4:	e8 52 d5 ff ff       	call   8010350b <end_op>
      return -1;
80105fb9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fbe:	e9 10 01 00 00       	jmp    801060d3 <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
80105fc3:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105fc6:	89 04 24             	mov    %eax,(%esp)
80105fc9:	e8 c9 c4 ff ff       	call   80102497 <namei>
80105fce:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105fd1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105fd5:	75 0f                	jne    80105fe6 <sys_open+0xad>
      end_op();
80105fd7:	e8 2f d5 ff ff       	call   8010350b <end_op>
      return -1;
80105fdc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fe1:	e9 ed 00 00 00       	jmp    801060d3 <sys_open+0x19a>
    }
    ilock(ip);
80105fe6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fe9:	89 04 24             	mov    %eax,(%esp)
80105fec:	e8 6c b9 ff ff       	call   8010195d <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105ff1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ff4:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105ff8:	66 83 f8 01          	cmp    $0x1,%ax
80105ffc:	75 21                	jne    8010601f <sys_open+0xe6>
80105ffe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106001:	85 c0                	test   %eax,%eax
80106003:	74 1a                	je     8010601f <sys_open+0xe6>
      iunlockput(ip);
80106005:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106008:	89 04 24             	mov    %eax,(%esp)
8010600b:	e8 4f bb ff ff       	call   80101b5f <iunlockput>
      end_op();
80106010:	e8 f6 d4 ff ff       	call   8010350b <end_op>
      return -1;
80106015:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010601a:	e9 b4 00 00 00       	jmp    801060d3 <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010601f:	e8 61 af ff ff       	call   80100f85 <filealloc>
80106024:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106027:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010602b:	74 14                	je     80106041 <sys_open+0x108>
8010602d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106030:	89 04 24             	mov    %eax,(%esp)
80106033:	e8 2d f7 ff ff       	call   80105765 <fdalloc>
80106038:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010603b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010603f:	79 28                	jns    80106069 <sys_open+0x130>
    if(f)
80106041:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106045:	74 0b                	je     80106052 <sys_open+0x119>
      fileclose(f);
80106047:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010604a:	89 04 24             	mov    %eax,(%esp)
8010604d:	e8 db af ff ff       	call   8010102d <fileclose>
    iunlockput(ip);
80106052:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106055:	89 04 24             	mov    %eax,(%esp)
80106058:	e8 02 bb ff ff       	call   80101b5f <iunlockput>
    end_op();
8010605d:	e8 a9 d4 ff ff       	call   8010350b <end_op>
    return -1;
80106062:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106067:	eb 6a                	jmp    801060d3 <sys_open+0x19a>
  }
  iunlock(ip);
80106069:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010606c:	89 04 24             	mov    %eax,(%esp)
8010606f:	e8 f6 b9 ff ff       	call   80101a6a <iunlock>
  end_op();
80106074:	e8 92 d4 ff ff       	call   8010350b <end_op>

  f->type = FD_INODE;
80106079:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010607c:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106082:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106085:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106088:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
8010608b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010608e:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106095:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106098:	83 e0 01             	and    $0x1,%eax
8010609b:	85 c0                	test   %eax,%eax
8010609d:	0f 94 c0             	sete   %al
801060a0:	89 c2                	mov    %eax,%edx
801060a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060a5:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801060a8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801060ab:	83 e0 01             	and    $0x1,%eax
801060ae:	85 c0                	test   %eax,%eax
801060b0:	75 0a                	jne    801060bc <sys_open+0x183>
801060b2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801060b5:	83 e0 02             	and    $0x2,%eax
801060b8:	85 c0                	test   %eax,%eax
801060ba:	74 07                	je     801060c3 <sys_open+0x18a>
801060bc:	b8 01 00 00 00       	mov    $0x1,%eax
801060c1:	eb 05                	jmp    801060c8 <sys_open+0x18f>
801060c3:	b8 00 00 00 00       	mov    $0x0,%eax
801060c8:	89 c2                	mov    %eax,%edx
801060ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060cd:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
801060d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
801060d3:	c9                   	leave  
801060d4:	c3                   	ret    

801060d5 <sys_mkdir>:

int
sys_mkdir(void)
{
801060d5:	55                   	push   %ebp
801060d6:	89 e5                	mov    %esp,%ebp
801060d8:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
801060db:	e8 a7 d3 ff ff       	call   80103487 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
801060e0:	8d 45 f0             	lea    -0x10(%ebp),%eax
801060e3:	89 44 24 04          	mov    %eax,0x4(%esp)
801060e7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060ee:	e8 3f f5 ff ff       	call   80105632 <argstr>
801060f3:	85 c0                	test   %eax,%eax
801060f5:	78 2c                	js     80106123 <sys_mkdir+0x4e>
801060f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060fa:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106101:	00 
80106102:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106109:	00 
8010610a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106111:	00 
80106112:	89 04 24             	mov    %eax,(%esp)
80106115:	e8 5f fc ff ff       	call   80105d79 <create>
8010611a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010611d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106121:	75 0c                	jne    8010612f <sys_mkdir+0x5a>
    end_op();
80106123:	e8 e3 d3 ff ff       	call   8010350b <end_op>
    return -1;
80106128:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010612d:	eb 15                	jmp    80106144 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
8010612f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106132:	89 04 24             	mov    %eax,(%esp)
80106135:	e8 25 ba ff ff       	call   80101b5f <iunlockput>
  end_op();
8010613a:	e8 cc d3 ff ff       	call   8010350b <end_op>
  return 0;
8010613f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106144:	c9                   	leave  
80106145:	c3                   	ret    

80106146 <sys_mknod>:

int
sys_mknod(void)
{
80106146:	55                   	push   %ebp
80106147:	89 e5                	mov    %esp,%ebp
80106149:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
8010614c:	e8 36 d3 ff ff       	call   80103487 <begin_op>
  if((argstr(0, &path)) < 0 ||
80106151:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106154:	89 44 24 04          	mov    %eax,0x4(%esp)
80106158:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010615f:	e8 ce f4 ff ff       	call   80105632 <argstr>
80106164:	85 c0                	test   %eax,%eax
80106166:	78 5e                	js     801061c6 <sys_mknod+0x80>
     argint(1, &major) < 0 ||
80106168:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010616b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010616f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106176:	e8 20 f4 ff ff       	call   8010559b <argint>
  if((argstr(0, &path)) < 0 ||
8010617b:	85 c0                	test   %eax,%eax
8010617d:	78 47                	js     801061c6 <sys_mknod+0x80>
     argint(2, &minor) < 0 ||
8010617f:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106182:	89 44 24 04          	mov    %eax,0x4(%esp)
80106186:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010618d:	e8 09 f4 ff ff       	call   8010559b <argint>
     argint(1, &major) < 0 ||
80106192:	85 c0                	test   %eax,%eax
80106194:	78 30                	js     801061c6 <sys_mknod+0x80>
     (ip = create(path, T_DEV, major, minor)) == 0){
80106196:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106199:	0f bf c8             	movswl %ax,%ecx
8010619c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010619f:	0f bf d0             	movswl %ax,%edx
801061a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
     argint(2, &minor) < 0 ||
801061a5:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801061a9:	89 54 24 08          	mov    %edx,0x8(%esp)
801061ad:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801061b4:	00 
801061b5:	89 04 24             	mov    %eax,(%esp)
801061b8:	e8 bc fb ff ff       	call   80105d79 <create>
801061bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
801061c0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801061c4:	75 0c                	jne    801061d2 <sys_mknod+0x8c>
    end_op();
801061c6:	e8 40 d3 ff ff       	call   8010350b <end_op>
    return -1;
801061cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061d0:	eb 15                	jmp    801061e7 <sys_mknod+0xa1>
  }
  iunlockput(ip);
801061d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061d5:	89 04 24             	mov    %eax,(%esp)
801061d8:	e8 82 b9 ff ff       	call   80101b5f <iunlockput>
  end_op();
801061dd:	e8 29 d3 ff ff       	call   8010350b <end_op>
  return 0;
801061e2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061e7:	c9                   	leave  
801061e8:	c3                   	ret    

801061e9 <sys_chdir>:

int
sys_chdir(void)
{
801061e9:	55                   	push   %ebp
801061ea:	89 e5                	mov    %esp,%ebp
801061ec:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
801061ef:	e8 6d df ff ff       	call   80104161 <myproc>
801061f4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  
  begin_op();
801061f7:	e8 8b d2 ff ff       	call   80103487 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
801061fc:	8d 45 ec             	lea    -0x14(%ebp),%eax
801061ff:	89 44 24 04          	mov    %eax,0x4(%esp)
80106203:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010620a:	e8 23 f4 ff ff       	call   80105632 <argstr>
8010620f:	85 c0                	test   %eax,%eax
80106211:	78 14                	js     80106227 <sys_chdir+0x3e>
80106213:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106216:	89 04 24             	mov    %eax,(%esp)
80106219:	e8 79 c2 ff ff       	call   80102497 <namei>
8010621e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106221:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106225:	75 0c                	jne    80106233 <sys_chdir+0x4a>
    end_op();
80106227:	e8 df d2 ff ff       	call   8010350b <end_op>
    return -1;
8010622c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106231:	eb 5b                	jmp    8010628e <sys_chdir+0xa5>
  }
  ilock(ip);
80106233:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106236:	89 04 24             	mov    %eax,(%esp)
80106239:	e8 1f b7 ff ff       	call   8010195d <ilock>
  if(ip->type != T_DIR){
8010623e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106241:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80106245:	66 83 f8 01          	cmp    $0x1,%ax
80106249:	74 17                	je     80106262 <sys_chdir+0x79>
    iunlockput(ip);
8010624b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010624e:	89 04 24             	mov    %eax,(%esp)
80106251:	e8 09 b9 ff ff       	call   80101b5f <iunlockput>
    end_op();
80106256:	e8 b0 d2 ff ff       	call   8010350b <end_op>
    return -1;
8010625b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106260:	eb 2c                	jmp    8010628e <sys_chdir+0xa5>
  }
  iunlock(ip);
80106262:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106265:	89 04 24             	mov    %eax,(%esp)
80106268:	e8 fd b7 ff ff       	call   80101a6a <iunlock>
  iput(curproc->cwd);
8010626d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106270:	8b 40 68             	mov    0x68(%eax),%eax
80106273:	89 04 24             	mov    %eax,(%esp)
80106276:	e8 33 b8 ff ff       	call   80101aae <iput>
  end_op();
8010627b:	e8 8b d2 ff ff       	call   8010350b <end_op>
  curproc->cwd = ip;
80106280:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106283:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106286:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106289:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010628e:	c9                   	leave  
8010628f:	c3                   	ret    

80106290 <sys_exec>:

int
sys_exec(void)
{
80106290:	55                   	push   %ebp
80106291:	89 e5                	mov    %esp,%ebp
80106293:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106299:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010629c:	89 44 24 04          	mov    %eax,0x4(%esp)
801062a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801062a7:	e8 86 f3 ff ff       	call   80105632 <argstr>
801062ac:	85 c0                	test   %eax,%eax
801062ae:	78 1a                	js     801062ca <sys_exec+0x3a>
801062b0:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
801062b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801062ba:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801062c1:	e8 d5 f2 ff ff       	call   8010559b <argint>
801062c6:	85 c0                	test   %eax,%eax
801062c8:	79 0a                	jns    801062d4 <sys_exec+0x44>
    return -1;
801062ca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062cf:	e9 c8 00 00 00       	jmp    8010639c <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
801062d4:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801062db:	00 
801062dc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801062e3:	00 
801062e4:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801062ea:	89 04 24             	mov    %eax,(%esp)
801062ed:	e8 60 ef ff ff       	call   80105252 <memset>
  for(i=0;; i++){
801062f2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
801062f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062fc:	83 f8 1f             	cmp    $0x1f,%eax
801062ff:	76 0a                	jbe    8010630b <sys_exec+0x7b>
      return -1;
80106301:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106306:	e9 91 00 00 00       	jmp    8010639c <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
8010630b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010630e:	c1 e0 02             	shl    $0x2,%eax
80106311:	89 c2                	mov    %eax,%edx
80106313:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106319:	01 c2                	add    %eax,%edx
8010631b:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106321:	89 44 24 04          	mov    %eax,0x4(%esp)
80106325:	89 14 24             	mov    %edx,(%esp)
80106328:	e8 cb f1 ff ff       	call   801054f8 <fetchint>
8010632d:	85 c0                	test   %eax,%eax
8010632f:	79 07                	jns    80106338 <sys_exec+0xa8>
      return -1;
80106331:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106336:	eb 64                	jmp    8010639c <sys_exec+0x10c>
    if(uarg == 0){
80106338:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
8010633e:	85 c0                	test   %eax,%eax
80106340:	75 26                	jne    80106368 <sys_exec+0xd8>
      argv[i] = 0;
80106342:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106345:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
8010634c:	00 00 00 00 
      break;
80106350:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106351:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106354:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
8010635a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010635e:	89 04 24             	mov    %eax,(%esp)
80106361:	e8 b8 a7 ff ff       	call   80100b1e <exec>
80106366:	eb 34                	jmp    8010639c <sys_exec+0x10c>
    if(fetchstr(uarg, &argv[i]) < 0)
80106368:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010636e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106371:	c1 e2 02             	shl    $0x2,%edx
80106374:	01 c2                	add    %eax,%edx
80106376:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
8010637c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106380:	89 04 24             	mov    %eax,(%esp)
80106383:	e8 af f1 ff ff       	call   80105537 <fetchstr>
80106388:	85 c0                	test   %eax,%eax
8010638a:	79 07                	jns    80106393 <sys_exec+0x103>
      return -1;
8010638c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106391:	eb 09                	jmp    8010639c <sys_exec+0x10c>
  for(i=0;; i++){
80106393:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }
80106397:	e9 5d ff ff ff       	jmp    801062f9 <sys_exec+0x69>
}
8010639c:	c9                   	leave  
8010639d:	c3                   	ret    

8010639e <sys_pipe>:

int
sys_pipe(void)
{
8010639e:	55                   	push   %ebp
8010639f:	89 e5                	mov    %esp,%ebp
801063a1:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
801063a4:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801063ab:	00 
801063ac:	8d 45 ec             	lea    -0x14(%ebp),%eax
801063af:	89 44 24 04          	mov    %eax,0x4(%esp)
801063b3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801063ba:	e8 09 f2 ff ff       	call   801055c8 <argptr>
801063bf:	85 c0                	test   %eax,%eax
801063c1:	79 0a                	jns    801063cd <sys_pipe+0x2f>
    return -1;
801063c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063c8:	e9 9a 00 00 00       	jmp    80106467 <sys_pipe+0xc9>
  if(pipealloc(&rf, &wf) < 0)
801063cd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801063d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801063d4:	8d 45 e8             	lea    -0x18(%ebp),%eax
801063d7:	89 04 24             	mov    %eax,(%esp)
801063da:	e8 06 d9 ff ff       	call   80103ce5 <pipealloc>
801063df:	85 c0                	test   %eax,%eax
801063e1:	79 07                	jns    801063ea <sys_pipe+0x4c>
    return -1;
801063e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063e8:	eb 7d                	jmp    80106467 <sys_pipe+0xc9>
  fd0 = -1;
801063ea:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
801063f1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801063f4:	89 04 24             	mov    %eax,(%esp)
801063f7:	e8 69 f3 ff ff       	call   80105765 <fdalloc>
801063fc:	89 45 f4             	mov    %eax,-0xc(%ebp)
801063ff:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106403:	78 14                	js     80106419 <sys_pipe+0x7b>
80106405:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106408:	89 04 24             	mov    %eax,(%esp)
8010640b:	e8 55 f3 ff ff       	call   80105765 <fdalloc>
80106410:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106413:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106417:	79 36                	jns    8010644f <sys_pipe+0xb1>
    if(fd0 >= 0)
80106419:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010641d:	78 13                	js     80106432 <sys_pipe+0x94>
      myproc()->ofile[fd0] = 0;
8010641f:	e8 3d dd ff ff       	call   80104161 <myproc>
80106424:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106427:	83 c2 08             	add    $0x8,%edx
8010642a:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106431:	00 
    fileclose(rf);
80106432:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106435:	89 04 24             	mov    %eax,(%esp)
80106438:	e8 f0 ab ff ff       	call   8010102d <fileclose>
    fileclose(wf);
8010643d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106440:	89 04 24             	mov    %eax,(%esp)
80106443:	e8 e5 ab ff ff       	call   8010102d <fileclose>
    return -1;
80106448:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010644d:	eb 18                	jmp    80106467 <sys_pipe+0xc9>
  }
  fd[0] = fd0;
8010644f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106452:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106455:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106457:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010645a:	8d 50 04             	lea    0x4(%eax),%edx
8010645d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106460:	89 02                	mov    %eax,(%edx)
  return 0;
80106462:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106467:	c9                   	leave  
80106468:	c3                   	ret    

80106469 <sys_fork>:

extern void fillpstat(pstatTable *);

int
sys_fork(void)
{
80106469:	55                   	push   %ebp
8010646a:	89 e5                	mov    %esp,%ebp
8010646c:	83 ec 08             	sub    $0x8,%esp
  return fork();
8010646f:	e8 05 e0 ff ff       	call   80104479 <fork>
}
80106474:	c9                   	leave  
80106475:	c3                   	ret    

80106476 <sys_exit>:

int
sys_exit(void)
{
80106476:	55                   	push   %ebp
80106477:	89 e5                	mov    %esp,%ebp
80106479:	83 ec 08             	sub    $0x8,%esp
  exit();
8010647c:	e8 8f e1 ff ff       	call   80104610 <exit>
  return 0;  // not reached
80106481:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106486:	c9                   	leave  
80106487:	c3                   	ret    

80106488 <sys_wait>:

int
sys_wait(void)
{
80106488:	55                   	push   %ebp
80106489:	89 e5                	mov    %esp,%ebp
8010648b:	83 ec 08             	sub    $0x8,%esp
  return wait();
8010648e:	e8 8a e2 ff ff       	call   8010471d <wait>
}
80106493:	c9                   	leave  
80106494:	c3                   	ret    

80106495 <sys_kill>:

int
sys_kill(void)
{
80106495:	55                   	push   %ebp
80106496:	89 e5                	mov    %esp,%ebp
80106498:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
8010649b:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010649e:	89 44 24 04          	mov    %eax,0x4(%esp)
801064a2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801064a9:	e8 ed f0 ff ff       	call   8010559b <argint>
801064ae:	85 c0                	test   %eax,%eax
801064b0:	79 07                	jns    801064b9 <sys_kill+0x24>
    return -1;
801064b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064b7:	eb 0b                	jmp    801064c4 <sys_kill+0x2f>
  return kill(pid);
801064b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064bc:	89 04 24             	mov    %eax,(%esp)
801064bf:	e8 37 e6 ff ff       	call   80104afb <kill>
}
801064c4:	c9                   	leave  
801064c5:	c3                   	ret    

801064c6 <sys_getpid>:

int
sys_getpid(void)
{
801064c6:	55                   	push   %ebp
801064c7:	89 e5                	mov    %esp,%ebp
801064c9:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
801064cc:	e8 90 dc ff ff       	call   80104161 <myproc>
801064d1:	8b 40 10             	mov    0x10(%eax),%eax
}
801064d4:	c9                   	leave  
801064d5:	c3                   	ret    

801064d6 <sys_sbrk>:

int
sys_sbrk(void)
{
801064d6:	55                   	push   %ebp
801064d7:	89 e5                	mov    %esp,%ebp
801064d9:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801064dc:	8d 45 f0             	lea    -0x10(%ebp),%eax
801064df:	89 44 24 04          	mov    %eax,0x4(%esp)
801064e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801064ea:	e8 ac f0 ff ff       	call   8010559b <argint>
801064ef:	85 c0                	test   %eax,%eax
801064f1:	79 07                	jns    801064fa <sys_sbrk+0x24>
    return -1;
801064f3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064f8:	eb 23                	jmp    8010651d <sys_sbrk+0x47>
  addr = myproc()->sz;
801064fa:	e8 62 dc ff ff       	call   80104161 <myproc>
801064ff:	8b 00                	mov    (%eax),%eax
80106501:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106504:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106507:	89 04 24             	mov    %eax,(%esp)
8010650a:	e8 cc de ff ff       	call   801043db <growproc>
8010650f:	85 c0                	test   %eax,%eax
80106511:	79 07                	jns    8010651a <sys_sbrk+0x44>
    return -1;
80106513:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106518:	eb 03                	jmp    8010651d <sys_sbrk+0x47>
  return addr;
8010651a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010651d:	c9                   	leave  
8010651e:	c3                   	ret    

8010651f <sys_sleep>:

int
sys_sleep(void)
{
8010651f:	55                   	push   %ebp
80106520:	89 e5                	mov    %esp,%ebp
80106522:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80106525:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106528:	89 44 24 04          	mov    %eax,0x4(%esp)
8010652c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106533:	e8 63 f0 ff ff       	call   8010559b <argint>
80106538:	85 c0                	test   %eax,%eax
8010653a:	79 07                	jns    80106543 <sys_sleep+0x24>
    return -1;
8010653c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106541:	eb 6b                	jmp    801065ae <sys_sleep+0x8f>
  acquire(&tickslock);
80106543:	c7 04 24 e0 5e 11 80 	movl   $0x80115ee0,(%esp)
8010654a:	e8 91 ea ff ff       	call   80104fe0 <acquire>
  ticks0 = ticks;
8010654f:	a1 20 67 11 80       	mov    0x80116720,%eax
80106554:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106557:	eb 33                	jmp    8010658c <sys_sleep+0x6d>
    if(myproc()->killed){
80106559:	e8 03 dc ff ff       	call   80104161 <myproc>
8010655e:	8b 40 24             	mov    0x24(%eax),%eax
80106561:	85 c0                	test   %eax,%eax
80106563:	74 13                	je     80106578 <sys_sleep+0x59>
      release(&tickslock);
80106565:	c7 04 24 e0 5e 11 80 	movl   $0x80115ee0,(%esp)
8010656c:	e8 d7 ea ff ff       	call   80105048 <release>
      return -1;
80106571:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106576:	eb 36                	jmp    801065ae <sys_sleep+0x8f>
    }
    sleep(&ticks, &tickslock);
80106578:	c7 44 24 04 e0 5e 11 	movl   $0x80115ee0,0x4(%esp)
8010657f:	80 
80106580:	c7 04 24 20 67 11 80 	movl   $0x80116720,(%esp)
80106587:	e8 6d e4 ff ff       	call   801049f9 <sleep>
  while(ticks - ticks0 < n){
8010658c:	a1 20 67 11 80       	mov    0x80116720,%eax
80106591:	2b 45 f4             	sub    -0xc(%ebp),%eax
80106594:	89 c2                	mov    %eax,%edx
80106596:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106599:	39 c2                	cmp    %eax,%edx
8010659b:	72 bc                	jb     80106559 <sys_sleep+0x3a>
  }
  release(&tickslock);
8010659d:	c7 04 24 e0 5e 11 80 	movl   $0x80115ee0,(%esp)
801065a4:	e8 9f ea ff ff       	call   80105048 <release>
  return 0;
801065a9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801065ae:	c9                   	leave  
801065af:	c3                   	ret    

801065b0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801065b0:	55                   	push   %ebp
801065b1:	89 e5                	mov    %esp,%ebp
801065b3:	83 ec 28             	sub    $0x28,%esp
  uint xticks;

  acquire(&tickslock);
801065b6:	c7 04 24 e0 5e 11 80 	movl   $0x80115ee0,(%esp)
801065bd:	e8 1e ea ff ff       	call   80104fe0 <acquire>
  xticks = ticks;
801065c2:	a1 20 67 11 80       	mov    0x80116720,%eax
801065c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
801065ca:	c7 04 24 e0 5e 11 80 	movl   $0x80115ee0,(%esp)
801065d1:	e8 72 ea ff ff       	call   80105048 <release>
  return xticks;
801065d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801065d9:	c9                   	leave  
801065da:	c3                   	ret    

801065db <sys_getpinfo>:

int
sys_getpinfo(void)
{
801065db:	55                   	push   %ebp
801065dc:	89 e5                	mov    %esp,%ebp
801065de:	83 ec 28             	sub    $0x28,%esp
	pstatTable *pstat;

	if (argptr(0, (void*)&pstat, sizeof(pstatTable)) < 0)
801065e1:	c7 44 24 08 00 09 00 	movl   $0x900,0x8(%esp)
801065e8:	00 
801065e9:	8d 45 f4             	lea    -0xc(%ebp),%eax
801065ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801065f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801065f7:	e8 cc ef ff ff       	call   801055c8 <argptr>
801065fc:	85 c0                	test   %eax,%eax
801065fe:	79 07                	jns    80106607 <sys_getpinfo+0x2c>
	{
		return -1;
80106600:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106605:	eb 10                	jmp    80106617 <sys_getpinfo+0x3c>
	}
	
	fillpstat(pstat);
80106607:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010660a:	89 04 24             	mov    %eax,(%esp)
8010660d:	e8 5e e6 ff ff       	call   80104c70 <fillpstat>
	return 0;
80106612:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106617:	c9                   	leave  
80106618:	c3                   	ret    

80106619 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106619:	1e                   	push   %ds
  pushl %es
8010661a:	06                   	push   %es
  pushl %fs
8010661b:	0f a0                	push   %fs
  pushl %gs
8010661d:	0f a8                	push   %gs
  pushal
8010661f:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80106620:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106624:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106626:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80106628:	54                   	push   %esp
  call trap
80106629:	e8 d8 01 00 00       	call   80106806 <trap>
  addl $4, %esp
8010662e:	83 c4 04             	add    $0x4,%esp

80106631 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106631:	61                   	popa   
  popl %gs
80106632:	0f a9                	pop    %gs
  popl %fs
80106634:	0f a1                	pop    %fs
  popl %es
80106636:	07                   	pop    %es
  popl %ds
80106637:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106638:	83 c4 08             	add    $0x8,%esp
  iret
8010663b:	cf                   	iret   

8010663c <lidt>:
{
8010663c:	55                   	push   %ebp
8010663d:	89 e5                	mov    %esp,%ebp
8010663f:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80106642:	8b 45 0c             	mov    0xc(%ebp),%eax
80106645:	83 e8 01             	sub    $0x1,%eax
80106648:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010664c:	8b 45 08             	mov    0x8(%ebp),%eax
8010664f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106653:	8b 45 08             	mov    0x8(%ebp),%eax
80106656:	c1 e8 10             	shr    $0x10,%eax
80106659:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
8010665d:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106660:	0f 01 18             	lidtl  (%eax)
}
80106663:	c9                   	leave  
80106664:	c3                   	ret    

80106665 <rcr2>:

static inline uint
rcr2(void)
{
80106665:	55                   	push   %ebp
80106666:	89 e5                	mov    %esp,%ebp
80106668:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010666b:	0f 20 d0             	mov    %cr2,%eax
8010666e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80106671:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106674:	c9                   	leave  
80106675:	c3                   	ret    

80106676 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106676:	55                   	push   %ebp
80106677:	89 e5                	mov    %esp,%ebp
80106679:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
8010667c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106683:	e9 c3 00 00 00       	jmp    8010674b <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106688:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010668b:	8b 04 85 7c b0 10 80 	mov    -0x7fef4f84(,%eax,4),%eax
80106692:	89 c2                	mov    %eax,%edx
80106694:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106697:	66 89 14 c5 20 5f 11 	mov    %dx,-0x7feea0e0(,%eax,8)
8010669e:	80 
8010669f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066a2:	66 c7 04 c5 22 5f 11 	movw   $0x8,-0x7feea0de(,%eax,8)
801066a9:	80 08 00 
801066ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066af:	0f b6 14 c5 24 5f 11 	movzbl -0x7feea0dc(,%eax,8),%edx
801066b6:	80 
801066b7:	83 e2 e0             	and    $0xffffffe0,%edx
801066ba:	88 14 c5 24 5f 11 80 	mov    %dl,-0x7feea0dc(,%eax,8)
801066c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066c4:	0f b6 14 c5 24 5f 11 	movzbl -0x7feea0dc(,%eax,8),%edx
801066cb:	80 
801066cc:	83 e2 1f             	and    $0x1f,%edx
801066cf:	88 14 c5 24 5f 11 80 	mov    %dl,-0x7feea0dc(,%eax,8)
801066d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066d9:	0f b6 14 c5 25 5f 11 	movzbl -0x7feea0db(,%eax,8),%edx
801066e0:	80 
801066e1:	83 e2 f0             	and    $0xfffffff0,%edx
801066e4:	83 ca 0e             	or     $0xe,%edx
801066e7:	88 14 c5 25 5f 11 80 	mov    %dl,-0x7feea0db(,%eax,8)
801066ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066f1:	0f b6 14 c5 25 5f 11 	movzbl -0x7feea0db(,%eax,8),%edx
801066f8:	80 
801066f9:	83 e2 ef             	and    $0xffffffef,%edx
801066fc:	88 14 c5 25 5f 11 80 	mov    %dl,-0x7feea0db(,%eax,8)
80106703:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106706:	0f b6 14 c5 25 5f 11 	movzbl -0x7feea0db(,%eax,8),%edx
8010670d:	80 
8010670e:	83 e2 9f             	and    $0xffffff9f,%edx
80106711:	88 14 c5 25 5f 11 80 	mov    %dl,-0x7feea0db(,%eax,8)
80106718:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010671b:	0f b6 14 c5 25 5f 11 	movzbl -0x7feea0db(,%eax,8),%edx
80106722:	80 
80106723:	83 ca 80             	or     $0xffffff80,%edx
80106726:	88 14 c5 25 5f 11 80 	mov    %dl,-0x7feea0db(,%eax,8)
8010672d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106730:	8b 04 85 7c b0 10 80 	mov    -0x7fef4f84(,%eax,4),%eax
80106737:	c1 e8 10             	shr    $0x10,%eax
8010673a:	89 c2                	mov    %eax,%edx
8010673c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010673f:	66 89 14 c5 26 5f 11 	mov    %dx,-0x7feea0da(,%eax,8)
80106746:	80 
  for(i = 0; i < 256; i++)
80106747:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010674b:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106752:	0f 8e 30 ff ff ff    	jle    80106688 <tvinit+0x12>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106758:	a1 7c b1 10 80       	mov    0x8010b17c,%eax
8010675d:	66 a3 20 61 11 80    	mov    %ax,0x80116120
80106763:	66 c7 05 22 61 11 80 	movw   $0x8,0x80116122
8010676a:	08 00 
8010676c:	0f b6 05 24 61 11 80 	movzbl 0x80116124,%eax
80106773:	83 e0 e0             	and    $0xffffffe0,%eax
80106776:	a2 24 61 11 80       	mov    %al,0x80116124
8010677b:	0f b6 05 24 61 11 80 	movzbl 0x80116124,%eax
80106782:	83 e0 1f             	and    $0x1f,%eax
80106785:	a2 24 61 11 80       	mov    %al,0x80116124
8010678a:	0f b6 05 25 61 11 80 	movzbl 0x80116125,%eax
80106791:	83 c8 0f             	or     $0xf,%eax
80106794:	a2 25 61 11 80       	mov    %al,0x80116125
80106799:	0f b6 05 25 61 11 80 	movzbl 0x80116125,%eax
801067a0:	83 e0 ef             	and    $0xffffffef,%eax
801067a3:	a2 25 61 11 80       	mov    %al,0x80116125
801067a8:	0f b6 05 25 61 11 80 	movzbl 0x80116125,%eax
801067af:	83 c8 60             	or     $0x60,%eax
801067b2:	a2 25 61 11 80       	mov    %al,0x80116125
801067b7:	0f b6 05 25 61 11 80 	movzbl 0x80116125,%eax
801067be:	83 c8 80             	or     $0xffffff80,%eax
801067c1:	a2 25 61 11 80       	mov    %al,0x80116125
801067c6:	a1 7c b1 10 80       	mov    0x8010b17c,%eax
801067cb:	c1 e8 10             	shr    $0x10,%eax
801067ce:	66 a3 26 61 11 80    	mov    %ax,0x80116126

  initlock(&tickslock, "time");
801067d4:	c7 44 24 04 5c 89 10 	movl   $0x8010895c,0x4(%esp)
801067db:	80 
801067dc:	c7 04 24 e0 5e 11 80 	movl   $0x80115ee0,(%esp)
801067e3:	e8 d7 e7 ff ff       	call   80104fbf <initlock>
}
801067e8:	c9                   	leave  
801067e9:	c3                   	ret    

801067ea <idtinit>:

void
idtinit(void)
{
801067ea:	55                   	push   %ebp
801067eb:	89 e5                	mov    %esp,%ebp
801067ed:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
801067f0:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
801067f7:	00 
801067f8:	c7 04 24 20 5f 11 80 	movl   $0x80115f20,(%esp)
801067ff:	e8 38 fe ff ff       	call   8010663c <lidt>
}
80106804:	c9                   	leave  
80106805:	c3                   	ret    

80106806 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106806:	55                   	push   %ebp
80106807:	89 e5                	mov    %esp,%ebp
80106809:	57                   	push   %edi
8010680a:	56                   	push   %esi
8010680b:	53                   	push   %ebx
8010680c:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
8010680f:	8b 45 08             	mov    0x8(%ebp),%eax
80106812:	8b 40 30             	mov    0x30(%eax),%eax
80106815:	83 f8 40             	cmp    $0x40,%eax
80106818:	75 3c                	jne    80106856 <trap+0x50>
    if(myproc()->killed)
8010681a:	e8 42 d9 ff ff       	call   80104161 <myproc>
8010681f:	8b 40 24             	mov    0x24(%eax),%eax
80106822:	85 c0                	test   %eax,%eax
80106824:	74 05                	je     8010682b <trap+0x25>
      exit();
80106826:	e8 e5 dd ff ff       	call   80104610 <exit>
    myproc()->tf = tf;
8010682b:	e8 31 d9 ff ff       	call   80104161 <myproc>
80106830:	8b 55 08             	mov    0x8(%ebp),%edx
80106833:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106836:	e8 2e ee ff ff       	call   80105669 <syscall>
    if(myproc()->killed)
8010683b:	e8 21 d9 ff ff       	call   80104161 <myproc>
80106840:	8b 40 24             	mov    0x24(%eax),%eax
80106843:	85 c0                	test   %eax,%eax
80106845:	74 0a                	je     80106851 <trap+0x4b>
      exit();
80106847:	e8 c4 dd ff ff       	call   80104610 <exit>
    return;
8010684c:	e9 19 02 00 00       	jmp    80106a6a <trap+0x264>
80106851:	e9 14 02 00 00       	jmp    80106a6a <trap+0x264>
  }

  switch(tf->trapno){
80106856:	8b 45 08             	mov    0x8(%ebp),%eax
80106859:	8b 40 30             	mov    0x30(%eax),%eax
8010685c:	83 e8 20             	sub    $0x20,%eax
8010685f:	83 f8 1f             	cmp    $0x1f,%eax
80106862:	0f 87 b1 00 00 00    	ja     80106919 <trap+0x113>
80106868:	8b 04 85 04 8a 10 80 	mov    -0x7fef75fc(,%eax,4),%eax
8010686f:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80106871:	e8 54 d8 ff ff       	call   801040ca <cpuid>
80106876:	85 c0                	test   %eax,%eax
80106878:	75 31                	jne    801068ab <trap+0xa5>
      acquire(&tickslock);
8010687a:	c7 04 24 e0 5e 11 80 	movl   $0x80115ee0,(%esp)
80106881:	e8 5a e7 ff ff       	call   80104fe0 <acquire>
      ticks++;
80106886:	a1 20 67 11 80       	mov    0x80116720,%eax
8010688b:	83 c0 01             	add    $0x1,%eax
8010688e:	a3 20 67 11 80       	mov    %eax,0x80116720
      wakeup(&ticks);
80106893:	c7 04 24 20 67 11 80 	movl   $0x80116720,(%esp)
8010689a:	e8 31 e2 ff ff       	call   80104ad0 <wakeup>
      release(&tickslock);
8010689f:	c7 04 24 e0 5e 11 80 	movl   $0x80115ee0,(%esp)
801068a6:	e8 9d e7 ff ff       	call   80105048 <release>
    }
    lapiceoi();
801068ab:	e8 a1 c6 ff ff       	call   80102f51 <lapiceoi>
    break;
801068b0:	e9 37 01 00 00       	jmp    801069ec <trap+0x1e6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801068b5:	e8 0e bf ff ff       	call   801027c8 <ideintr>
    lapiceoi();
801068ba:	e8 92 c6 ff ff       	call   80102f51 <lapiceoi>
    break;
801068bf:	e9 28 01 00 00       	jmp    801069ec <trap+0x1e6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801068c4:	e8 9d c4 ff ff       	call   80102d66 <kbdintr>
    lapiceoi();
801068c9:	e8 83 c6 ff ff       	call   80102f51 <lapiceoi>
    break;
801068ce:	e9 19 01 00 00       	jmp    801069ec <trap+0x1e6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801068d3:	e8 7b 03 00 00       	call   80106c53 <uartintr>
    lapiceoi();
801068d8:	e8 74 c6 ff ff       	call   80102f51 <lapiceoi>
    break;
801068dd:	e9 0a 01 00 00       	jmp    801069ec <trap+0x1e6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801068e2:	8b 45 08             	mov    0x8(%ebp),%eax
801068e5:	8b 70 38             	mov    0x38(%eax),%esi
            cpuid(), tf->cs, tf->eip);
801068e8:	8b 45 08             	mov    0x8(%ebp),%eax
801068eb:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801068ef:	0f b7 d8             	movzwl %ax,%ebx
801068f2:	e8 d3 d7 ff ff       	call   801040ca <cpuid>
801068f7:	89 74 24 0c          	mov    %esi,0xc(%esp)
801068fb:	89 5c 24 08          	mov    %ebx,0x8(%esp)
801068ff:	89 44 24 04          	mov    %eax,0x4(%esp)
80106903:	c7 04 24 64 89 10 80 	movl   $0x80108964,(%esp)
8010690a:	e8 b9 9a ff ff       	call   801003c8 <cprintf>
    lapiceoi();
8010690f:	e8 3d c6 ff ff       	call   80102f51 <lapiceoi>
    break;
80106914:	e9 d3 00 00 00       	jmp    801069ec <trap+0x1e6>

  //PAGEBREAK: 13
  default:
    if(myproc() == 0 || (tf->cs&3) == 0){
80106919:	e8 43 d8 ff ff       	call   80104161 <myproc>
8010691e:	85 c0                	test   %eax,%eax
80106920:	74 11                	je     80106933 <trap+0x12d>
80106922:	8b 45 08             	mov    0x8(%ebp),%eax
80106925:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106929:	0f b7 c0             	movzwl %ax,%eax
8010692c:	83 e0 03             	and    $0x3,%eax
8010692f:	85 c0                	test   %eax,%eax
80106931:	75 40                	jne    80106973 <trap+0x16d>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106933:	e8 2d fd ff ff       	call   80106665 <rcr2>
80106938:	89 c3                	mov    %eax,%ebx
8010693a:	8b 45 08             	mov    0x8(%ebp),%eax
8010693d:	8b 70 38             	mov    0x38(%eax),%esi
80106940:	e8 85 d7 ff ff       	call   801040ca <cpuid>
80106945:	8b 55 08             	mov    0x8(%ebp),%edx
80106948:	8b 52 30             	mov    0x30(%edx),%edx
8010694b:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010694f:	89 74 24 0c          	mov    %esi,0xc(%esp)
80106953:	89 44 24 08          	mov    %eax,0x8(%esp)
80106957:	89 54 24 04          	mov    %edx,0x4(%esp)
8010695b:	c7 04 24 88 89 10 80 	movl   $0x80108988,(%esp)
80106962:	e8 61 9a ff ff       	call   801003c8 <cprintf>
              tf->trapno, cpuid(), tf->eip, rcr2());
      panic("trap");
80106967:	c7 04 24 ba 89 10 80 	movl   $0x801089ba,(%esp)
8010696e:	e8 ef 9b ff ff       	call   80100562 <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106973:	e8 ed fc ff ff       	call   80106665 <rcr2>
80106978:	89 c6                	mov    %eax,%esi
8010697a:	8b 45 08             	mov    0x8(%ebp),%eax
8010697d:	8b 40 38             	mov    0x38(%eax),%eax
80106980:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106983:	e8 42 d7 ff ff       	call   801040ca <cpuid>
80106988:	89 c3                	mov    %eax,%ebx
8010698a:	8b 45 08             	mov    0x8(%ebp),%eax
8010698d:	8b 78 34             	mov    0x34(%eax),%edi
80106990:	89 7d e0             	mov    %edi,-0x20(%ebp)
80106993:	8b 45 08             	mov    0x8(%ebp),%eax
80106996:	8b 78 30             	mov    0x30(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            myproc()->pid, myproc()->name, tf->trapno,
80106999:	e8 c3 d7 ff ff       	call   80104161 <myproc>
8010699e:	8d 50 6c             	lea    0x6c(%eax),%edx
801069a1:	89 55 dc             	mov    %edx,-0x24(%ebp)
801069a4:	e8 b8 d7 ff ff       	call   80104161 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801069a9:	8b 40 10             	mov    0x10(%eax),%eax
801069ac:	89 74 24 1c          	mov    %esi,0x1c(%esp)
801069b0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801069b3:	89 4c 24 18          	mov    %ecx,0x18(%esp)
801069b7:	89 5c 24 14          	mov    %ebx,0x14(%esp)
801069bb:	8b 4d e0             	mov    -0x20(%ebp),%ecx
801069be:	89 4c 24 10          	mov    %ecx,0x10(%esp)
801069c2:	89 7c 24 0c          	mov    %edi,0xc(%esp)
801069c6:	8b 55 dc             	mov    -0x24(%ebp),%edx
801069c9:	89 54 24 08          	mov    %edx,0x8(%esp)
801069cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801069d1:	c7 04 24 c0 89 10 80 	movl   $0x801089c0,(%esp)
801069d8:	e8 eb 99 ff ff       	call   801003c8 <cprintf>
            tf->err, cpuid(), tf->eip, rcr2());
    myproc()->killed = 1;
801069dd:	e8 7f d7 ff ff       	call   80104161 <myproc>
801069e2:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801069e9:	eb 01                	jmp    801069ec <trap+0x1e6>
    break;
801069eb:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
801069ec:	e8 70 d7 ff ff       	call   80104161 <myproc>
801069f1:	85 c0                	test   %eax,%eax
801069f3:	74 23                	je     80106a18 <trap+0x212>
801069f5:	e8 67 d7 ff ff       	call   80104161 <myproc>
801069fa:	8b 40 24             	mov    0x24(%eax),%eax
801069fd:	85 c0                	test   %eax,%eax
801069ff:	74 17                	je     80106a18 <trap+0x212>
80106a01:	8b 45 08             	mov    0x8(%ebp),%eax
80106a04:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106a08:	0f b7 c0             	movzwl %ax,%eax
80106a0b:	83 e0 03             	and    $0x3,%eax
80106a0e:	83 f8 03             	cmp    $0x3,%eax
80106a11:	75 05                	jne    80106a18 <trap+0x212>
    exit();
80106a13:	e8 f8 db ff ff       	call   80104610 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80106a18:	e8 44 d7 ff ff       	call   80104161 <myproc>
80106a1d:	85 c0                	test   %eax,%eax
80106a1f:	74 1d                	je     80106a3e <trap+0x238>
80106a21:	e8 3b d7 ff ff       	call   80104161 <myproc>
80106a26:	8b 40 0c             	mov    0xc(%eax),%eax
80106a29:	83 f8 04             	cmp    $0x4,%eax
80106a2c:	75 10                	jne    80106a3e <trap+0x238>
     tf->trapno == T_IRQ0+IRQ_TIMER)
80106a2e:	8b 45 08             	mov    0x8(%ebp),%eax
80106a31:	8b 40 30             	mov    0x30(%eax),%eax
  if(myproc() && myproc()->state == RUNNING &&
80106a34:	83 f8 20             	cmp    $0x20,%eax
80106a37:	75 05                	jne    80106a3e <trap+0x238>
    yield();
80106a39:	e8 4b df ff ff       	call   80104989 <yield>

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80106a3e:	e8 1e d7 ff ff       	call   80104161 <myproc>
80106a43:	85 c0                	test   %eax,%eax
80106a45:	74 23                	je     80106a6a <trap+0x264>
80106a47:	e8 15 d7 ff ff       	call   80104161 <myproc>
80106a4c:	8b 40 24             	mov    0x24(%eax),%eax
80106a4f:	85 c0                	test   %eax,%eax
80106a51:	74 17                	je     80106a6a <trap+0x264>
80106a53:	8b 45 08             	mov    0x8(%ebp),%eax
80106a56:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106a5a:	0f b7 c0             	movzwl %ax,%eax
80106a5d:	83 e0 03             	and    $0x3,%eax
80106a60:	83 f8 03             	cmp    $0x3,%eax
80106a63:	75 05                	jne    80106a6a <trap+0x264>
    exit();
80106a65:	e8 a6 db ff ff       	call   80104610 <exit>
}
80106a6a:	83 c4 3c             	add    $0x3c,%esp
80106a6d:	5b                   	pop    %ebx
80106a6e:	5e                   	pop    %esi
80106a6f:	5f                   	pop    %edi
80106a70:	5d                   	pop    %ebp
80106a71:	c3                   	ret    

80106a72 <inb>:
{
80106a72:	55                   	push   %ebp
80106a73:	89 e5                	mov    %esp,%ebp
80106a75:	83 ec 14             	sub    $0x14,%esp
80106a78:	8b 45 08             	mov    0x8(%ebp),%eax
80106a7b:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106a7f:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80106a83:	89 c2                	mov    %eax,%edx
80106a85:	ec                   	in     (%dx),%al
80106a86:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80106a89:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80106a8d:	c9                   	leave  
80106a8e:	c3                   	ret    

80106a8f <outb>:
{
80106a8f:	55                   	push   %ebp
80106a90:	89 e5                	mov    %esp,%ebp
80106a92:	83 ec 08             	sub    $0x8,%esp
80106a95:	8b 55 08             	mov    0x8(%ebp),%edx
80106a98:	8b 45 0c             	mov    0xc(%ebp),%eax
80106a9b:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106a9f:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106aa2:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106aa6:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106aaa:	ee                   	out    %al,(%dx)
}
80106aab:	c9                   	leave  
80106aac:	c3                   	ret    

80106aad <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106aad:	55                   	push   %ebp
80106aae:	89 e5                	mov    %esp,%ebp
80106ab0:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106ab3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106aba:	00 
80106abb:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106ac2:	e8 c8 ff ff ff       	call   80106a8f <outb>

  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106ac7:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106ace:	00 
80106acf:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106ad6:	e8 b4 ff ff ff       	call   80106a8f <outb>
  outb(COM1+0, 115200/9600);
80106adb:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106ae2:	00 
80106ae3:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106aea:	e8 a0 ff ff ff       	call   80106a8f <outb>
  outb(COM1+1, 0);
80106aef:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106af6:	00 
80106af7:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106afe:	e8 8c ff ff ff       	call   80106a8f <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106b03:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106b0a:	00 
80106b0b:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106b12:	e8 78 ff ff ff       	call   80106a8f <outb>
  outb(COM1+4, 0);
80106b17:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b1e:	00 
80106b1f:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106b26:	e8 64 ff ff ff       	call   80106a8f <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106b2b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106b32:	00 
80106b33:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106b3a:	e8 50 ff ff ff       	call   80106a8f <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106b3f:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106b46:	e8 27 ff ff ff       	call   80106a72 <inb>
80106b4b:	3c ff                	cmp    $0xff,%al
80106b4d:	75 02                	jne    80106b51 <uartinit+0xa4>
    return;
80106b4f:	eb 5e                	jmp    80106baf <uartinit+0x102>
  uart = 1;
80106b51:	c7 05 24 b6 10 80 01 	movl   $0x1,0x8010b624
80106b58:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106b5b:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106b62:	e8 0b ff ff ff       	call   80106a72 <inb>
  inb(COM1+0);
80106b67:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106b6e:	e8 ff fe ff ff       	call   80106a72 <inb>
  ioapicenable(IRQ_COM1, 0);
80106b73:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b7a:	00 
80106b7b:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106b82:	e8 b8 be ff ff       	call   80102a3f <ioapicenable>

  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106b87:	c7 45 f4 84 8a 10 80 	movl   $0x80108a84,-0xc(%ebp)
80106b8e:	eb 15                	jmp    80106ba5 <uartinit+0xf8>
    uartputc(*p);
80106b90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b93:	0f b6 00             	movzbl (%eax),%eax
80106b96:	0f be c0             	movsbl %al,%eax
80106b99:	89 04 24             	mov    %eax,(%esp)
80106b9c:	e8 10 00 00 00       	call   80106bb1 <uartputc>
  for(p="xv6...\n"; *p; p++)
80106ba1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106ba5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ba8:	0f b6 00             	movzbl (%eax),%eax
80106bab:	84 c0                	test   %al,%al
80106bad:	75 e1                	jne    80106b90 <uartinit+0xe3>
}
80106baf:	c9                   	leave  
80106bb0:	c3                   	ret    

80106bb1 <uartputc>:

void
uartputc(int c)
{
80106bb1:	55                   	push   %ebp
80106bb2:	89 e5                	mov    %esp,%ebp
80106bb4:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106bb7:	a1 24 b6 10 80       	mov    0x8010b624,%eax
80106bbc:	85 c0                	test   %eax,%eax
80106bbe:	75 02                	jne    80106bc2 <uartputc+0x11>
    return;
80106bc0:	eb 4b                	jmp    80106c0d <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106bc2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106bc9:	eb 10                	jmp    80106bdb <uartputc+0x2a>
    microdelay(10);
80106bcb:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106bd2:	e8 9f c3 ff ff       	call   80102f76 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106bd7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106bdb:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106bdf:	7f 16                	jg     80106bf7 <uartputc+0x46>
80106be1:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106be8:	e8 85 fe ff ff       	call   80106a72 <inb>
80106bed:	0f b6 c0             	movzbl %al,%eax
80106bf0:	83 e0 20             	and    $0x20,%eax
80106bf3:	85 c0                	test   %eax,%eax
80106bf5:	74 d4                	je     80106bcb <uartputc+0x1a>
  outb(COM1+0, c);
80106bf7:	8b 45 08             	mov    0x8(%ebp),%eax
80106bfa:	0f b6 c0             	movzbl %al,%eax
80106bfd:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c01:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106c08:	e8 82 fe ff ff       	call   80106a8f <outb>
}
80106c0d:	c9                   	leave  
80106c0e:	c3                   	ret    

80106c0f <uartgetc>:

static int
uartgetc(void)
{
80106c0f:	55                   	push   %ebp
80106c10:	89 e5                	mov    %esp,%ebp
80106c12:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106c15:	a1 24 b6 10 80       	mov    0x8010b624,%eax
80106c1a:	85 c0                	test   %eax,%eax
80106c1c:	75 07                	jne    80106c25 <uartgetc+0x16>
    return -1;
80106c1e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c23:	eb 2c                	jmp    80106c51 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106c25:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106c2c:	e8 41 fe ff ff       	call   80106a72 <inb>
80106c31:	0f b6 c0             	movzbl %al,%eax
80106c34:	83 e0 01             	and    $0x1,%eax
80106c37:	85 c0                	test   %eax,%eax
80106c39:	75 07                	jne    80106c42 <uartgetc+0x33>
    return -1;
80106c3b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c40:	eb 0f                	jmp    80106c51 <uartgetc+0x42>
  return inb(COM1+0);
80106c42:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106c49:	e8 24 fe ff ff       	call   80106a72 <inb>
80106c4e:	0f b6 c0             	movzbl %al,%eax
}
80106c51:	c9                   	leave  
80106c52:	c3                   	ret    

80106c53 <uartintr>:

void
uartintr(void)
{
80106c53:	55                   	push   %ebp
80106c54:	89 e5                	mov    %esp,%ebp
80106c56:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106c59:	c7 04 24 0f 6c 10 80 	movl   $0x80106c0f,(%esp)
80106c60:	e8 84 9b ff ff       	call   801007e9 <consoleintr>
}
80106c65:	c9                   	leave  
80106c66:	c3                   	ret    

80106c67 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106c67:	6a 00                	push   $0x0
  pushl $0
80106c69:	6a 00                	push   $0x0
  jmp alltraps
80106c6b:	e9 a9 f9 ff ff       	jmp    80106619 <alltraps>

80106c70 <vector1>:
.globl vector1
vector1:
  pushl $0
80106c70:	6a 00                	push   $0x0
  pushl $1
80106c72:	6a 01                	push   $0x1
  jmp alltraps
80106c74:	e9 a0 f9 ff ff       	jmp    80106619 <alltraps>

80106c79 <vector2>:
.globl vector2
vector2:
  pushl $0
80106c79:	6a 00                	push   $0x0
  pushl $2
80106c7b:	6a 02                	push   $0x2
  jmp alltraps
80106c7d:	e9 97 f9 ff ff       	jmp    80106619 <alltraps>

80106c82 <vector3>:
.globl vector3
vector3:
  pushl $0
80106c82:	6a 00                	push   $0x0
  pushl $3
80106c84:	6a 03                	push   $0x3
  jmp alltraps
80106c86:	e9 8e f9 ff ff       	jmp    80106619 <alltraps>

80106c8b <vector4>:
.globl vector4
vector4:
  pushl $0
80106c8b:	6a 00                	push   $0x0
  pushl $4
80106c8d:	6a 04                	push   $0x4
  jmp alltraps
80106c8f:	e9 85 f9 ff ff       	jmp    80106619 <alltraps>

80106c94 <vector5>:
.globl vector5
vector5:
  pushl $0
80106c94:	6a 00                	push   $0x0
  pushl $5
80106c96:	6a 05                	push   $0x5
  jmp alltraps
80106c98:	e9 7c f9 ff ff       	jmp    80106619 <alltraps>

80106c9d <vector6>:
.globl vector6
vector6:
  pushl $0
80106c9d:	6a 00                	push   $0x0
  pushl $6
80106c9f:	6a 06                	push   $0x6
  jmp alltraps
80106ca1:	e9 73 f9 ff ff       	jmp    80106619 <alltraps>

80106ca6 <vector7>:
.globl vector7
vector7:
  pushl $0
80106ca6:	6a 00                	push   $0x0
  pushl $7
80106ca8:	6a 07                	push   $0x7
  jmp alltraps
80106caa:	e9 6a f9 ff ff       	jmp    80106619 <alltraps>

80106caf <vector8>:
.globl vector8
vector8:
  pushl $8
80106caf:	6a 08                	push   $0x8
  jmp alltraps
80106cb1:	e9 63 f9 ff ff       	jmp    80106619 <alltraps>

80106cb6 <vector9>:
.globl vector9
vector9:
  pushl $0
80106cb6:	6a 00                	push   $0x0
  pushl $9
80106cb8:	6a 09                	push   $0x9
  jmp alltraps
80106cba:	e9 5a f9 ff ff       	jmp    80106619 <alltraps>

80106cbf <vector10>:
.globl vector10
vector10:
  pushl $10
80106cbf:	6a 0a                	push   $0xa
  jmp alltraps
80106cc1:	e9 53 f9 ff ff       	jmp    80106619 <alltraps>

80106cc6 <vector11>:
.globl vector11
vector11:
  pushl $11
80106cc6:	6a 0b                	push   $0xb
  jmp alltraps
80106cc8:	e9 4c f9 ff ff       	jmp    80106619 <alltraps>

80106ccd <vector12>:
.globl vector12
vector12:
  pushl $12
80106ccd:	6a 0c                	push   $0xc
  jmp alltraps
80106ccf:	e9 45 f9 ff ff       	jmp    80106619 <alltraps>

80106cd4 <vector13>:
.globl vector13
vector13:
  pushl $13
80106cd4:	6a 0d                	push   $0xd
  jmp alltraps
80106cd6:	e9 3e f9 ff ff       	jmp    80106619 <alltraps>

80106cdb <vector14>:
.globl vector14
vector14:
  pushl $14
80106cdb:	6a 0e                	push   $0xe
  jmp alltraps
80106cdd:	e9 37 f9 ff ff       	jmp    80106619 <alltraps>

80106ce2 <vector15>:
.globl vector15
vector15:
  pushl $0
80106ce2:	6a 00                	push   $0x0
  pushl $15
80106ce4:	6a 0f                	push   $0xf
  jmp alltraps
80106ce6:	e9 2e f9 ff ff       	jmp    80106619 <alltraps>

80106ceb <vector16>:
.globl vector16
vector16:
  pushl $0
80106ceb:	6a 00                	push   $0x0
  pushl $16
80106ced:	6a 10                	push   $0x10
  jmp alltraps
80106cef:	e9 25 f9 ff ff       	jmp    80106619 <alltraps>

80106cf4 <vector17>:
.globl vector17
vector17:
  pushl $17
80106cf4:	6a 11                	push   $0x11
  jmp alltraps
80106cf6:	e9 1e f9 ff ff       	jmp    80106619 <alltraps>

80106cfb <vector18>:
.globl vector18
vector18:
  pushl $0
80106cfb:	6a 00                	push   $0x0
  pushl $18
80106cfd:	6a 12                	push   $0x12
  jmp alltraps
80106cff:	e9 15 f9 ff ff       	jmp    80106619 <alltraps>

80106d04 <vector19>:
.globl vector19
vector19:
  pushl $0
80106d04:	6a 00                	push   $0x0
  pushl $19
80106d06:	6a 13                	push   $0x13
  jmp alltraps
80106d08:	e9 0c f9 ff ff       	jmp    80106619 <alltraps>

80106d0d <vector20>:
.globl vector20
vector20:
  pushl $0
80106d0d:	6a 00                	push   $0x0
  pushl $20
80106d0f:	6a 14                	push   $0x14
  jmp alltraps
80106d11:	e9 03 f9 ff ff       	jmp    80106619 <alltraps>

80106d16 <vector21>:
.globl vector21
vector21:
  pushl $0
80106d16:	6a 00                	push   $0x0
  pushl $21
80106d18:	6a 15                	push   $0x15
  jmp alltraps
80106d1a:	e9 fa f8 ff ff       	jmp    80106619 <alltraps>

80106d1f <vector22>:
.globl vector22
vector22:
  pushl $0
80106d1f:	6a 00                	push   $0x0
  pushl $22
80106d21:	6a 16                	push   $0x16
  jmp alltraps
80106d23:	e9 f1 f8 ff ff       	jmp    80106619 <alltraps>

80106d28 <vector23>:
.globl vector23
vector23:
  pushl $0
80106d28:	6a 00                	push   $0x0
  pushl $23
80106d2a:	6a 17                	push   $0x17
  jmp alltraps
80106d2c:	e9 e8 f8 ff ff       	jmp    80106619 <alltraps>

80106d31 <vector24>:
.globl vector24
vector24:
  pushl $0
80106d31:	6a 00                	push   $0x0
  pushl $24
80106d33:	6a 18                	push   $0x18
  jmp alltraps
80106d35:	e9 df f8 ff ff       	jmp    80106619 <alltraps>

80106d3a <vector25>:
.globl vector25
vector25:
  pushl $0
80106d3a:	6a 00                	push   $0x0
  pushl $25
80106d3c:	6a 19                	push   $0x19
  jmp alltraps
80106d3e:	e9 d6 f8 ff ff       	jmp    80106619 <alltraps>

80106d43 <vector26>:
.globl vector26
vector26:
  pushl $0
80106d43:	6a 00                	push   $0x0
  pushl $26
80106d45:	6a 1a                	push   $0x1a
  jmp alltraps
80106d47:	e9 cd f8 ff ff       	jmp    80106619 <alltraps>

80106d4c <vector27>:
.globl vector27
vector27:
  pushl $0
80106d4c:	6a 00                	push   $0x0
  pushl $27
80106d4e:	6a 1b                	push   $0x1b
  jmp alltraps
80106d50:	e9 c4 f8 ff ff       	jmp    80106619 <alltraps>

80106d55 <vector28>:
.globl vector28
vector28:
  pushl $0
80106d55:	6a 00                	push   $0x0
  pushl $28
80106d57:	6a 1c                	push   $0x1c
  jmp alltraps
80106d59:	e9 bb f8 ff ff       	jmp    80106619 <alltraps>

80106d5e <vector29>:
.globl vector29
vector29:
  pushl $0
80106d5e:	6a 00                	push   $0x0
  pushl $29
80106d60:	6a 1d                	push   $0x1d
  jmp alltraps
80106d62:	e9 b2 f8 ff ff       	jmp    80106619 <alltraps>

80106d67 <vector30>:
.globl vector30
vector30:
  pushl $0
80106d67:	6a 00                	push   $0x0
  pushl $30
80106d69:	6a 1e                	push   $0x1e
  jmp alltraps
80106d6b:	e9 a9 f8 ff ff       	jmp    80106619 <alltraps>

80106d70 <vector31>:
.globl vector31
vector31:
  pushl $0
80106d70:	6a 00                	push   $0x0
  pushl $31
80106d72:	6a 1f                	push   $0x1f
  jmp alltraps
80106d74:	e9 a0 f8 ff ff       	jmp    80106619 <alltraps>

80106d79 <vector32>:
.globl vector32
vector32:
  pushl $0
80106d79:	6a 00                	push   $0x0
  pushl $32
80106d7b:	6a 20                	push   $0x20
  jmp alltraps
80106d7d:	e9 97 f8 ff ff       	jmp    80106619 <alltraps>

80106d82 <vector33>:
.globl vector33
vector33:
  pushl $0
80106d82:	6a 00                	push   $0x0
  pushl $33
80106d84:	6a 21                	push   $0x21
  jmp alltraps
80106d86:	e9 8e f8 ff ff       	jmp    80106619 <alltraps>

80106d8b <vector34>:
.globl vector34
vector34:
  pushl $0
80106d8b:	6a 00                	push   $0x0
  pushl $34
80106d8d:	6a 22                	push   $0x22
  jmp alltraps
80106d8f:	e9 85 f8 ff ff       	jmp    80106619 <alltraps>

80106d94 <vector35>:
.globl vector35
vector35:
  pushl $0
80106d94:	6a 00                	push   $0x0
  pushl $35
80106d96:	6a 23                	push   $0x23
  jmp alltraps
80106d98:	e9 7c f8 ff ff       	jmp    80106619 <alltraps>

80106d9d <vector36>:
.globl vector36
vector36:
  pushl $0
80106d9d:	6a 00                	push   $0x0
  pushl $36
80106d9f:	6a 24                	push   $0x24
  jmp alltraps
80106da1:	e9 73 f8 ff ff       	jmp    80106619 <alltraps>

80106da6 <vector37>:
.globl vector37
vector37:
  pushl $0
80106da6:	6a 00                	push   $0x0
  pushl $37
80106da8:	6a 25                	push   $0x25
  jmp alltraps
80106daa:	e9 6a f8 ff ff       	jmp    80106619 <alltraps>

80106daf <vector38>:
.globl vector38
vector38:
  pushl $0
80106daf:	6a 00                	push   $0x0
  pushl $38
80106db1:	6a 26                	push   $0x26
  jmp alltraps
80106db3:	e9 61 f8 ff ff       	jmp    80106619 <alltraps>

80106db8 <vector39>:
.globl vector39
vector39:
  pushl $0
80106db8:	6a 00                	push   $0x0
  pushl $39
80106dba:	6a 27                	push   $0x27
  jmp alltraps
80106dbc:	e9 58 f8 ff ff       	jmp    80106619 <alltraps>

80106dc1 <vector40>:
.globl vector40
vector40:
  pushl $0
80106dc1:	6a 00                	push   $0x0
  pushl $40
80106dc3:	6a 28                	push   $0x28
  jmp alltraps
80106dc5:	e9 4f f8 ff ff       	jmp    80106619 <alltraps>

80106dca <vector41>:
.globl vector41
vector41:
  pushl $0
80106dca:	6a 00                	push   $0x0
  pushl $41
80106dcc:	6a 29                	push   $0x29
  jmp alltraps
80106dce:	e9 46 f8 ff ff       	jmp    80106619 <alltraps>

80106dd3 <vector42>:
.globl vector42
vector42:
  pushl $0
80106dd3:	6a 00                	push   $0x0
  pushl $42
80106dd5:	6a 2a                	push   $0x2a
  jmp alltraps
80106dd7:	e9 3d f8 ff ff       	jmp    80106619 <alltraps>

80106ddc <vector43>:
.globl vector43
vector43:
  pushl $0
80106ddc:	6a 00                	push   $0x0
  pushl $43
80106dde:	6a 2b                	push   $0x2b
  jmp alltraps
80106de0:	e9 34 f8 ff ff       	jmp    80106619 <alltraps>

80106de5 <vector44>:
.globl vector44
vector44:
  pushl $0
80106de5:	6a 00                	push   $0x0
  pushl $44
80106de7:	6a 2c                	push   $0x2c
  jmp alltraps
80106de9:	e9 2b f8 ff ff       	jmp    80106619 <alltraps>

80106dee <vector45>:
.globl vector45
vector45:
  pushl $0
80106dee:	6a 00                	push   $0x0
  pushl $45
80106df0:	6a 2d                	push   $0x2d
  jmp alltraps
80106df2:	e9 22 f8 ff ff       	jmp    80106619 <alltraps>

80106df7 <vector46>:
.globl vector46
vector46:
  pushl $0
80106df7:	6a 00                	push   $0x0
  pushl $46
80106df9:	6a 2e                	push   $0x2e
  jmp alltraps
80106dfb:	e9 19 f8 ff ff       	jmp    80106619 <alltraps>

80106e00 <vector47>:
.globl vector47
vector47:
  pushl $0
80106e00:	6a 00                	push   $0x0
  pushl $47
80106e02:	6a 2f                	push   $0x2f
  jmp alltraps
80106e04:	e9 10 f8 ff ff       	jmp    80106619 <alltraps>

80106e09 <vector48>:
.globl vector48
vector48:
  pushl $0
80106e09:	6a 00                	push   $0x0
  pushl $48
80106e0b:	6a 30                	push   $0x30
  jmp alltraps
80106e0d:	e9 07 f8 ff ff       	jmp    80106619 <alltraps>

80106e12 <vector49>:
.globl vector49
vector49:
  pushl $0
80106e12:	6a 00                	push   $0x0
  pushl $49
80106e14:	6a 31                	push   $0x31
  jmp alltraps
80106e16:	e9 fe f7 ff ff       	jmp    80106619 <alltraps>

80106e1b <vector50>:
.globl vector50
vector50:
  pushl $0
80106e1b:	6a 00                	push   $0x0
  pushl $50
80106e1d:	6a 32                	push   $0x32
  jmp alltraps
80106e1f:	e9 f5 f7 ff ff       	jmp    80106619 <alltraps>

80106e24 <vector51>:
.globl vector51
vector51:
  pushl $0
80106e24:	6a 00                	push   $0x0
  pushl $51
80106e26:	6a 33                	push   $0x33
  jmp alltraps
80106e28:	e9 ec f7 ff ff       	jmp    80106619 <alltraps>

80106e2d <vector52>:
.globl vector52
vector52:
  pushl $0
80106e2d:	6a 00                	push   $0x0
  pushl $52
80106e2f:	6a 34                	push   $0x34
  jmp alltraps
80106e31:	e9 e3 f7 ff ff       	jmp    80106619 <alltraps>

80106e36 <vector53>:
.globl vector53
vector53:
  pushl $0
80106e36:	6a 00                	push   $0x0
  pushl $53
80106e38:	6a 35                	push   $0x35
  jmp alltraps
80106e3a:	e9 da f7 ff ff       	jmp    80106619 <alltraps>

80106e3f <vector54>:
.globl vector54
vector54:
  pushl $0
80106e3f:	6a 00                	push   $0x0
  pushl $54
80106e41:	6a 36                	push   $0x36
  jmp alltraps
80106e43:	e9 d1 f7 ff ff       	jmp    80106619 <alltraps>

80106e48 <vector55>:
.globl vector55
vector55:
  pushl $0
80106e48:	6a 00                	push   $0x0
  pushl $55
80106e4a:	6a 37                	push   $0x37
  jmp alltraps
80106e4c:	e9 c8 f7 ff ff       	jmp    80106619 <alltraps>

80106e51 <vector56>:
.globl vector56
vector56:
  pushl $0
80106e51:	6a 00                	push   $0x0
  pushl $56
80106e53:	6a 38                	push   $0x38
  jmp alltraps
80106e55:	e9 bf f7 ff ff       	jmp    80106619 <alltraps>

80106e5a <vector57>:
.globl vector57
vector57:
  pushl $0
80106e5a:	6a 00                	push   $0x0
  pushl $57
80106e5c:	6a 39                	push   $0x39
  jmp alltraps
80106e5e:	e9 b6 f7 ff ff       	jmp    80106619 <alltraps>

80106e63 <vector58>:
.globl vector58
vector58:
  pushl $0
80106e63:	6a 00                	push   $0x0
  pushl $58
80106e65:	6a 3a                	push   $0x3a
  jmp alltraps
80106e67:	e9 ad f7 ff ff       	jmp    80106619 <alltraps>

80106e6c <vector59>:
.globl vector59
vector59:
  pushl $0
80106e6c:	6a 00                	push   $0x0
  pushl $59
80106e6e:	6a 3b                	push   $0x3b
  jmp alltraps
80106e70:	e9 a4 f7 ff ff       	jmp    80106619 <alltraps>

80106e75 <vector60>:
.globl vector60
vector60:
  pushl $0
80106e75:	6a 00                	push   $0x0
  pushl $60
80106e77:	6a 3c                	push   $0x3c
  jmp alltraps
80106e79:	e9 9b f7 ff ff       	jmp    80106619 <alltraps>

80106e7e <vector61>:
.globl vector61
vector61:
  pushl $0
80106e7e:	6a 00                	push   $0x0
  pushl $61
80106e80:	6a 3d                	push   $0x3d
  jmp alltraps
80106e82:	e9 92 f7 ff ff       	jmp    80106619 <alltraps>

80106e87 <vector62>:
.globl vector62
vector62:
  pushl $0
80106e87:	6a 00                	push   $0x0
  pushl $62
80106e89:	6a 3e                	push   $0x3e
  jmp alltraps
80106e8b:	e9 89 f7 ff ff       	jmp    80106619 <alltraps>

80106e90 <vector63>:
.globl vector63
vector63:
  pushl $0
80106e90:	6a 00                	push   $0x0
  pushl $63
80106e92:	6a 3f                	push   $0x3f
  jmp alltraps
80106e94:	e9 80 f7 ff ff       	jmp    80106619 <alltraps>

80106e99 <vector64>:
.globl vector64
vector64:
  pushl $0
80106e99:	6a 00                	push   $0x0
  pushl $64
80106e9b:	6a 40                	push   $0x40
  jmp alltraps
80106e9d:	e9 77 f7 ff ff       	jmp    80106619 <alltraps>

80106ea2 <vector65>:
.globl vector65
vector65:
  pushl $0
80106ea2:	6a 00                	push   $0x0
  pushl $65
80106ea4:	6a 41                	push   $0x41
  jmp alltraps
80106ea6:	e9 6e f7 ff ff       	jmp    80106619 <alltraps>

80106eab <vector66>:
.globl vector66
vector66:
  pushl $0
80106eab:	6a 00                	push   $0x0
  pushl $66
80106ead:	6a 42                	push   $0x42
  jmp alltraps
80106eaf:	e9 65 f7 ff ff       	jmp    80106619 <alltraps>

80106eb4 <vector67>:
.globl vector67
vector67:
  pushl $0
80106eb4:	6a 00                	push   $0x0
  pushl $67
80106eb6:	6a 43                	push   $0x43
  jmp alltraps
80106eb8:	e9 5c f7 ff ff       	jmp    80106619 <alltraps>

80106ebd <vector68>:
.globl vector68
vector68:
  pushl $0
80106ebd:	6a 00                	push   $0x0
  pushl $68
80106ebf:	6a 44                	push   $0x44
  jmp alltraps
80106ec1:	e9 53 f7 ff ff       	jmp    80106619 <alltraps>

80106ec6 <vector69>:
.globl vector69
vector69:
  pushl $0
80106ec6:	6a 00                	push   $0x0
  pushl $69
80106ec8:	6a 45                	push   $0x45
  jmp alltraps
80106eca:	e9 4a f7 ff ff       	jmp    80106619 <alltraps>

80106ecf <vector70>:
.globl vector70
vector70:
  pushl $0
80106ecf:	6a 00                	push   $0x0
  pushl $70
80106ed1:	6a 46                	push   $0x46
  jmp alltraps
80106ed3:	e9 41 f7 ff ff       	jmp    80106619 <alltraps>

80106ed8 <vector71>:
.globl vector71
vector71:
  pushl $0
80106ed8:	6a 00                	push   $0x0
  pushl $71
80106eda:	6a 47                	push   $0x47
  jmp alltraps
80106edc:	e9 38 f7 ff ff       	jmp    80106619 <alltraps>

80106ee1 <vector72>:
.globl vector72
vector72:
  pushl $0
80106ee1:	6a 00                	push   $0x0
  pushl $72
80106ee3:	6a 48                	push   $0x48
  jmp alltraps
80106ee5:	e9 2f f7 ff ff       	jmp    80106619 <alltraps>

80106eea <vector73>:
.globl vector73
vector73:
  pushl $0
80106eea:	6a 00                	push   $0x0
  pushl $73
80106eec:	6a 49                	push   $0x49
  jmp alltraps
80106eee:	e9 26 f7 ff ff       	jmp    80106619 <alltraps>

80106ef3 <vector74>:
.globl vector74
vector74:
  pushl $0
80106ef3:	6a 00                	push   $0x0
  pushl $74
80106ef5:	6a 4a                	push   $0x4a
  jmp alltraps
80106ef7:	e9 1d f7 ff ff       	jmp    80106619 <alltraps>

80106efc <vector75>:
.globl vector75
vector75:
  pushl $0
80106efc:	6a 00                	push   $0x0
  pushl $75
80106efe:	6a 4b                	push   $0x4b
  jmp alltraps
80106f00:	e9 14 f7 ff ff       	jmp    80106619 <alltraps>

80106f05 <vector76>:
.globl vector76
vector76:
  pushl $0
80106f05:	6a 00                	push   $0x0
  pushl $76
80106f07:	6a 4c                	push   $0x4c
  jmp alltraps
80106f09:	e9 0b f7 ff ff       	jmp    80106619 <alltraps>

80106f0e <vector77>:
.globl vector77
vector77:
  pushl $0
80106f0e:	6a 00                	push   $0x0
  pushl $77
80106f10:	6a 4d                	push   $0x4d
  jmp alltraps
80106f12:	e9 02 f7 ff ff       	jmp    80106619 <alltraps>

80106f17 <vector78>:
.globl vector78
vector78:
  pushl $0
80106f17:	6a 00                	push   $0x0
  pushl $78
80106f19:	6a 4e                	push   $0x4e
  jmp alltraps
80106f1b:	e9 f9 f6 ff ff       	jmp    80106619 <alltraps>

80106f20 <vector79>:
.globl vector79
vector79:
  pushl $0
80106f20:	6a 00                	push   $0x0
  pushl $79
80106f22:	6a 4f                	push   $0x4f
  jmp alltraps
80106f24:	e9 f0 f6 ff ff       	jmp    80106619 <alltraps>

80106f29 <vector80>:
.globl vector80
vector80:
  pushl $0
80106f29:	6a 00                	push   $0x0
  pushl $80
80106f2b:	6a 50                	push   $0x50
  jmp alltraps
80106f2d:	e9 e7 f6 ff ff       	jmp    80106619 <alltraps>

80106f32 <vector81>:
.globl vector81
vector81:
  pushl $0
80106f32:	6a 00                	push   $0x0
  pushl $81
80106f34:	6a 51                	push   $0x51
  jmp alltraps
80106f36:	e9 de f6 ff ff       	jmp    80106619 <alltraps>

80106f3b <vector82>:
.globl vector82
vector82:
  pushl $0
80106f3b:	6a 00                	push   $0x0
  pushl $82
80106f3d:	6a 52                	push   $0x52
  jmp alltraps
80106f3f:	e9 d5 f6 ff ff       	jmp    80106619 <alltraps>

80106f44 <vector83>:
.globl vector83
vector83:
  pushl $0
80106f44:	6a 00                	push   $0x0
  pushl $83
80106f46:	6a 53                	push   $0x53
  jmp alltraps
80106f48:	e9 cc f6 ff ff       	jmp    80106619 <alltraps>

80106f4d <vector84>:
.globl vector84
vector84:
  pushl $0
80106f4d:	6a 00                	push   $0x0
  pushl $84
80106f4f:	6a 54                	push   $0x54
  jmp alltraps
80106f51:	e9 c3 f6 ff ff       	jmp    80106619 <alltraps>

80106f56 <vector85>:
.globl vector85
vector85:
  pushl $0
80106f56:	6a 00                	push   $0x0
  pushl $85
80106f58:	6a 55                	push   $0x55
  jmp alltraps
80106f5a:	e9 ba f6 ff ff       	jmp    80106619 <alltraps>

80106f5f <vector86>:
.globl vector86
vector86:
  pushl $0
80106f5f:	6a 00                	push   $0x0
  pushl $86
80106f61:	6a 56                	push   $0x56
  jmp alltraps
80106f63:	e9 b1 f6 ff ff       	jmp    80106619 <alltraps>

80106f68 <vector87>:
.globl vector87
vector87:
  pushl $0
80106f68:	6a 00                	push   $0x0
  pushl $87
80106f6a:	6a 57                	push   $0x57
  jmp alltraps
80106f6c:	e9 a8 f6 ff ff       	jmp    80106619 <alltraps>

80106f71 <vector88>:
.globl vector88
vector88:
  pushl $0
80106f71:	6a 00                	push   $0x0
  pushl $88
80106f73:	6a 58                	push   $0x58
  jmp alltraps
80106f75:	e9 9f f6 ff ff       	jmp    80106619 <alltraps>

80106f7a <vector89>:
.globl vector89
vector89:
  pushl $0
80106f7a:	6a 00                	push   $0x0
  pushl $89
80106f7c:	6a 59                	push   $0x59
  jmp alltraps
80106f7e:	e9 96 f6 ff ff       	jmp    80106619 <alltraps>

80106f83 <vector90>:
.globl vector90
vector90:
  pushl $0
80106f83:	6a 00                	push   $0x0
  pushl $90
80106f85:	6a 5a                	push   $0x5a
  jmp alltraps
80106f87:	e9 8d f6 ff ff       	jmp    80106619 <alltraps>

80106f8c <vector91>:
.globl vector91
vector91:
  pushl $0
80106f8c:	6a 00                	push   $0x0
  pushl $91
80106f8e:	6a 5b                	push   $0x5b
  jmp alltraps
80106f90:	e9 84 f6 ff ff       	jmp    80106619 <alltraps>

80106f95 <vector92>:
.globl vector92
vector92:
  pushl $0
80106f95:	6a 00                	push   $0x0
  pushl $92
80106f97:	6a 5c                	push   $0x5c
  jmp alltraps
80106f99:	e9 7b f6 ff ff       	jmp    80106619 <alltraps>

80106f9e <vector93>:
.globl vector93
vector93:
  pushl $0
80106f9e:	6a 00                	push   $0x0
  pushl $93
80106fa0:	6a 5d                	push   $0x5d
  jmp alltraps
80106fa2:	e9 72 f6 ff ff       	jmp    80106619 <alltraps>

80106fa7 <vector94>:
.globl vector94
vector94:
  pushl $0
80106fa7:	6a 00                	push   $0x0
  pushl $94
80106fa9:	6a 5e                	push   $0x5e
  jmp alltraps
80106fab:	e9 69 f6 ff ff       	jmp    80106619 <alltraps>

80106fb0 <vector95>:
.globl vector95
vector95:
  pushl $0
80106fb0:	6a 00                	push   $0x0
  pushl $95
80106fb2:	6a 5f                	push   $0x5f
  jmp alltraps
80106fb4:	e9 60 f6 ff ff       	jmp    80106619 <alltraps>

80106fb9 <vector96>:
.globl vector96
vector96:
  pushl $0
80106fb9:	6a 00                	push   $0x0
  pushl $96
80106fbb:	6a 60                	push   $0x60
  jmp alltraps
80106fbd:	e9 57 f6 ff ff       	jmp    80106619 <alltraps>

80106fc2 <vector97>:
.globl vector97
vector97:
  pushl $0
80106fc2:	6a 00                	push   $0x0
  pushl $97
80106fc4:	6a 61                	push   $0x61
  jmp alltraps
80106fc6:	e9 4e f6 ff ff       	jmp    80106619 <alltraps>

80106fcb <vector98>:
.globl vector98
vector98:
  pushl $0
80106fcb:	6a 00                	push   $0x0
  pushl $98
80106fcd:	6a 62                	push   $0x62
  jmp alltraps
80106fcf:	e9 45 f6 ff ff       	jmp    80106619 <alltraps>

80106fd4 <vector99>:
.globl vector99
vector99:
  pushl $0
80106fd4:	6a 00                	push   $0x0
  pushl $99
80106fd6:	6a 63                	push   $0x63
  jmp alltraps
80106fd8:	e9 3c f6 ff ff       	jmp    80106619 <alltraps>

80106fdd <vector100>:
.globl vector100
vector100:
  pushl $0
80106fdd:	6a 00                	push   $0x0
  pushl $100
80106fdf:	6a 64                	push   $0x64
  jmp alltraps
80106fe1:	e9 33 f6 ff ff       	jmp    80106619 <alltraps>

80106fe6 <vector101>:
.globl vector101
vector101:
  pushl $0
80106fe6:	6a 00                	push   $0x0
  pushl $101
80106fe8:	6a 65                	push   $0x65
  jmp alltraps
80106fea:	e9 2a f6 ff ff       	jmp    80106619 <alltraps>

80106fef <vector102>:
.globl vector102
vector102:
  pushl $0
80106fef:	6a 00                	push   $0x0
  pushl $102
80106ff1:	6a 66                	push   $0x66
  jmp alltraps
80106ff3:	e9 21 f6 ff ff       	jmp    80106619 <alltraps>

80106ff8 <vector103>:
.globl vector103
vector103:
  pushl $0
80106ff8:	6a 00                	push   $0x0
  pushl $103
80106ffa:	6a 67                	push   $0x67
  jmp alltraps
80106ffc:	e9 18 f6 ff ff       	jmp    80106619 <alltraps>

80107001 <vector104>:
.globl vector104
vector104:
  pushl $0
80107001:	6a 00                	push   $0x0
  pushl $104
80107003:	6a 68                	push   $0x68
  jmp alltraps
80107005:	e9 0f f6 ff ff       	jmp    80106619 <alltraps>

8010700a <vector105>:
.globl vector105
vector105:
  pushl $0
8010700a:	6a 00                	push   $0x0
  pushl $105
8010700c:	6a 69                	push   $0x69
  jmp alltraps
8010700e:	e9 06 f6 ff ff       	jmp    80106619 <alltraps>

80107013 <vector106>:
.globl vector106
vector106:
  pushl $0
80107013:	6a 00                	push   $0x0
  pushl $106
80107015:	6a 6a                	push   $0x6a
  jmp alltraps
80107017:	e9 fd f5 ff ff       	jmp    80106619 <alltraps>

8010701c <vector107>:
.globl vector107
vector107:
  pushl $0
8010701c:	6a 00                	push   $0x0
  pushl $107
8010701e:	6a 6b                	push   $0x6b
  jmp alltraps
80107020:	e9 f4 f5 ff ff       	jmp    80106619 <alltraps>

80107025 <vector108>:
.globl vector108
vector108:
  pushl $0
80107025:	6a 00                	push   $0x0
  pushl $108
80107027:	6a 6c                	push   $0x6c
  jmp alltraps
80107029:	e9 eb f5 ff ff       	jmp    80106619 <alltraps>

8010702e <vector109>:
.globl vector109
vector109:
  pushl $0
8010702e:	6a 00                	push   $0x0
  pushl $109
80107030:	6a 6d                	push   $0x6d
  jmp alltraps
80107032:	e9 e2 f5 ff ff       	jmp    80106619 <alltraps>

80107037 <vector110>:
.globl vector110
vector110:
  pushl $0
80107037:	6a 00                	push   $0x0
  pushl $110
80107039:	6a 6e                	push   $0x6e
  jmp alltraps
8010703b:	e9 d9 f5 ff ff       	jmp    80106619 <alltraps>

80107040 <vector111>:
.globl vector111
vector111:
  pushl $0
80107040:	6a 00                	push   $0x0
  pushl $111
80107042:	6a 6f                	push   $0x6f
  jmp alltraps
80107044:	e9 d0 f5 ff ff       	jmp    80106619 <alltraps>

80107049 <vector112>:
.globl vector112
vector112:
  pushl $0
80107049:	6a 00                	push   $0x0
  pushl $112
8010704b:	6a 70                	push   $0x70
  jmp alltraps
8010704d:	e9 c7 f5 ff ff       	jmp    80106619 <alltraps>

80107052 <vector113>:
.globl vector113
vector113:
  pushl $0
80107052:	6a 00                	push   $0x0
  pushl $113
80107054:	6a 71                	push   $0x71
  jmp alltraps
80107056:	e9 be f5 ff ff       	jmp    80106619 <alltraps>

8010705b <vector114>:
.globl vector114
vector114:
  pushl $0
8010705b:	6a 00                	push   $0x0
  pushl $114
8010705d:	6a 72                	push   $0x72
  jmp alltraps
8010705f:	e9 b5 f5 ff ff       	jmp    80106619 <alltraps>

80107064 <vector115>:
.globl vector115
vector115:
  pushl $0
80107064:	6a 00                	push   $0x0
  pushl $115
80107066:	6a 73                	push   $0x73
  jmp alltraps
80107068:	e9 ac f5 ff ff       	jmp    80106619 <alltraps>

8010706d <vector116>:
.globl vector116
vector116:
  pushl $0
8010706d:	6a 00                	push   $0x0
  pushl $116
8010706f:	6a 74                	push   $0x74
  jmp alltraps
80107071:	e9 a3 f5 ff ff       	jmp    80106619 <alltraps>

80107076 <vector117>:
.globl vector117
vector117:
  pushl $0
80107076:	6a 00                	push   $0x0
  pushl $117
80107078:	6a 75                	push   $0x75
  jmp alltraps
8010707a:	e9 9a f5 ff ff       	jmp    80106619 <alltraps>

8010707f <vector118>:
.globl vector118
vector118:
  pushl $0
8010707f:	6a 00                	push   $0x0
  pushl $118
80107081:	6a 76                	push   $0x76
  jmp alltraps
80107083:	e9 91 f5 ff ff       	jmp    80106619 <alltraps>

80107088 <vector119>:
.globl vector119
vector119:
  pushl $0
80107088:	6a 00                	push   $0x0
  pushl $119
8010708a:	6a 77                	push   $0x77
  jmp alltraps
8010708c:	e9 88 f5 ff ff       	jmp    80106619 <alltraps>

80107091 <vector120>:
.globl vector120
vector120:
  pushl $0
80107091:	6a 00                	push   $0x0
  pushl $120
80107093:	6a 78                	push   $0x78
  jmp alltraps
80107095:	e9 7f f5 ff ff       	jmp    80106619 <alltraps>

8010709a <vector121>:
.globl vector121
vector121:
  pushl $0
8010709a:	6a 00                	push   $0x0
  pushl $121
8010709c:	6a 79                	push   $0x79
  jmp alltraps
8010709e:	e9 76 f5 ff ff       	jmp    80106619 <alltraps>

801070a3 <vector122>:
.globl vector122
vector122:
  pushl $0
801070a3:	6a 00                	push   $0x0
  pushl $122
801070a5:	6a 7a                	push   $0x7a
  jmp alltraps
801070a7:	e9 6d f5 ff ff       	jmp    80106619 <alltraps>

801070ac <vector123>:
.globl vector123
vector123:
  pushl $0
801070ac:	6a 00                	push   $0x0
  pushl $123
801070ae:	6a 7b                	push   $0x7b
  jmp alltraps
801070b0:	e9 64 f5 ff ff       	jmp    80106619 <alltraps>

801070b5 <vector124>:
.globl vector124
vector124:
  pushl $0
801070b5:	6a 00                	push   $0x0
  pushl $124
801070b7:	6a 7c                	push   $0x7c
  jmp alltraps
801070b9:	e9 5b f5 ff ff       	jmp    80106619 <alltraps>

801070be <vector125>:
.globl vector125
vector125:
  pushl $0
801070be:	6a 00                	push   $0x0
  pushl $125
801070c0:	6a 7d                	push   $0x7d
  jmp alltraps
801070c2:	e9 52 f5 ff ff       	jmp    80106619 <alltraps>

801070c7 <vector126>:
.globl vector126
vector126:
  pushl $0
801070c7:	6a 00                	push   $0x0
  pushl $126
801070c9:	6a 7e                	push   $0x7e
  jmp alltraps
801070cb:	e9 49 f5 ff ff       	jmp    80106619 <alltraps>

801070d0 <vector127>:
.globl vector127
vector127:
  pushl $0
801070d0:	6a 00                	push   $0x0
  pushl $127
801070d2:	6a 7f                	push   $0x7f
  jmp alltraps
801070d4:	e9 40 f5 ff ff       	jmp    80106619 <alltraps>

801070d9 <vector128>:
.globl vector128
vector128:
  pushl $0
801070d9:	6a 00                	push   $0x0
  pushl $128
801070db:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801070e0:	e9 34 f5 ff ff       	jmp    80106619 <alltraps>

801070e5 <vector129>:
.globl vector129
vector129:
  pushl $0
801070e5:	6a 00                	push   $0x0
  pushl $129
801070e7:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801070ec:	e9 28 f5 ff ff       	jmp    80106619 <alltraps>

801070f1 <vector130>:
.globl vector130
vector130:
  pushl $0
801070f1:	6a 00                	push   $0x0
  pushl $130
801070f3:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801070f8:	e9 1c f5 ff ff       	jmp    80106619 <alltraps>

801070fd <vector131>:
.globl vector131
vector131:
  pushl $0
801070fd:	6a 00                	push   $0x0
  pushl $131
801070ff:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107104:	e9 10 f5 ff ff       	jmp    80106619 <alltraps>

80107109 <vector132>:
.globl vector132
vector132:
  pushl $0
80107109:	6a 00                	push   $0x0
  pushl $132
8010710b:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107110:	e9 04 f5 ff ff       	jmp    80106619 <alltraps>

80107115 <vector133>:
.globl vector133
vector133:
  pushl $0
80107115:	6a 00                	push   $0x0
  pushl $133
80107117:	68 85 00 00 00       	push   $0x85
  jmp alltraps
8010711c:	e9 f8 f4 ff ff       	jmp    80106619 <alltraps>

80107121 <vector134>:
.globl vector134
vector134:
  pushl $0
80107121:	6a 00                	push   $0x0
  pushl $134
80107123:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107128:	e9 ec f4 ff ff       	jmp    80106619 <alltraps>

8010712d <vector135>:
.globl vector135
vector135:
  pushl $0
8010712d:	6a 00                	push   $0x0
  pushl $135
8010712f:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107134:	e9 e0 f4 ff ff       	jmp    80106619 <alltraps>

80107139 <vector136>:
.globl vector136
vector136:
  pushl $0
80107139:	6a 00                	push   $0x0
  pushl $136
8010713b:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107140:	e9 d4 f4 ff ff       	jmp    80106619 <alltraps>

80107145 <vector137>:
.globl vector137
vector137:
  pushl $0
80107145:	6a 00                	push   $0x0
  pushl $137
80107147:	68 89 00 00 00       	push   $0x89
  jmp alltraps
8010714c:	e9 c8 f4 ff ff       	jmp    80106619 <alltraps>

80107151 <vector138>:
.globl vector138
vector138:
  pushl $0
80107151:	6a 00                	push   $0x0
  pushl $138
80107153:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107158:	e9 bc f4 ff ff       	jmp    80106619 <alltraps>

8010715d <vector139>:
.globl vector139
vector139:
  pushl $0
8010715d:	6a 00                	push   $0x0
  pushl $139
8010715f:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107164:	e9 b0 f4 ff ff       	jmp    80106619 <alltraps>

80107169 <vector140>:
.globl vector140
vector140:
  pushl $0
80107169:	6a 00                	push   $0x0
  pushl $140
8010716b:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107170:	e9 a4 f4 ff ff       	jmp    80106619 <alltraps>

80107175 <vector141>:
.globl vector141
vector141:
  pushl $0
80107175:	6a 00                	push   $0x0
  pushl $141
80107177:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
8010717c:	e9 98 f4 ff ff       	jmp    80106619 <alltraps>

80107181 <vector142>:
.globl vector142
vector142:
  pushl $0
80107181:	6a 00                	push   $0x0
  pushl $142
80107183:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107188:	e9 8c f4 ff ff       	jmp    80106619 <alltraps>

8010718d <vector143>:
.globl vector143
vector143:
  pushl $0
8010718d:	6a 00                	push   $0x0
  pushl $143
8010718f:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107194:	e9 80 f4 ff ff       	jmp    80106619 <alltraps>

80107199 <vector144>:
.globl vector144
vector144:
  pushl $0
80107199:	6a 00                	push   $0x0
  pushl $144
8010719b:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801071a0:	e9 74 f4 ff ff       	jmp    80106619 <alltraps>

801071a5 <vector145>:
.globl vector145
vector145:
  pushl $0
801071a5:	6a 00                	push   $0x0
  pushl $145
801071a7:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801071ac:	e9 68 f4 ff ff       	jmp    80106619 <alltraps>

801071b1 <vector146>:
.globl vector146
vector146:
  pushl $0
801071b1:	6a 00                	push   $0x0
  pushl $146
801071b3:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801071b8:	e9 5c f4 ff ff       	jmp    80106619 <alltraps>

801071bd <vector147>:
.globl vector147
vector147:
  pushl $0
801071bd:	6a 00                	push   $0x0
  pushl $147
801071bf:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801071c4:	e9 50 f4 ff ff       	jmp    80106619 <alltraps>

801071c9 <vector148>:
.globl vector148
vector148:
  pushl $0
801071c9:	6a 00                	push   $0x0
  pushl $148
801071cb:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801071d0:	e9 44 f4 ff ff       	jmp    80106619 <alltraps>

801071d5 <vector149>:
.globl vector149
vector149:
  pushl $0
801071d5:	6a 00                	push   $0x0
  pushl $149
801071d7:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801071dc:	e9 38 f4 ff ff       	jmp    80106619 <alltraps>

801071e1 <vector150>:
.globl vector150
vector150:
  pushl $0
801071e1:	6a 00                	push   $0x0
  pushl $150
801071e3:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801071e8:	e9 2c f4 ff ff       	jmp    80106619 <alltraps>

801071ed <vector151>:
.globl vector151
vector151:
  pushl $0
801071ed:	6a 00                	push   $0x0
  pushl $151
801071ef:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801071f4:	e9 20 f4 ff ff       	jmp    80106619 <alltraps>

801071f9 <vector152>:
.globl vector152
vector152:
  pushl $0
801071f9:	6a 00                	push   $0x0
  pushl $152
801071fb:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107200:	e9 14 f4 ff ff       	jmp    80106619 <alltraps>

80107205 <vector153>:
.globl vector153
vector153:
  pushl $0
80107205:	6a 00                	push   $0x0
  pushl $153
80107207:	68 99 00 00 00       	push   $0x99
  jmp alltraps
8010720c:	e9 08 f4 ff ff       	jmp    80106619 <alltraps>

80107211 <vector154>:
.globl vector154
vector154:
  pushl $0
80107211:	6a 00                	push   $0x0
  pushl $154
80107213:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107218:	e9 fc f3 ff ff       	jmp    80106619 <alltraps>

8010721d <vector155>:
.globl vector155
vector155:
  pushl $0
8010721d:	6a 00                	push   $0x0
  pushl $155
8010721f:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107224:	e9 f0 f3 ff ff       	jmp    80106619 <alltraps>

80107229 <vector156>:
.globl vector156
vector156:
  pushl $0
80107229:	6a 00                	push   $0x0
  pushl $156
8010722b:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107230:	e9 e4 f3 ff ff       	jmp    80106619 <alltraps>

80107235 <vector157>:
.globl vector157
vector157:
  pushl $0
80107235:	6a 00                	push   $0x0
  pushl $157
80107237:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
8010723c:	e9 d8 f3 ff ff       	jmp    80106619 <alltraps>

80107241 <vector158>:
.globl vector158
vector158:
  pushl $0
80107241:	6a 00                	push   $0x0
  pushl $158
80107243:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107248:	e9 cc f3 ff ff       	jmp    80106619 <alltraps>

8010724d <vector159>:
.globl vector159
vector159:
  pushl $0
8010724d:	6a 00                	push   $0x0
  pushl $159
8010724f:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107254:	e9 c0 f3 ff ff       	jmp    80106619 <alltraps>

80107259 <vector160>:
.globl vector160
vector160:
  pushl $0
80107259:	6a 00                	push   $0x0
  pushl $160
8010725b:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107260:	e9 b4 f3 ff ff       	jmp    80106619 <alltraps>

80107265 <vector161>:
.globl vector161
vector161:
  pushl $0
80107265:	6a 00                	push   $0x0
  pushl $161
80107267:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
8010726c:	e9 a8 f3 ff ff       	jmp    80106619 <alltraps>

80107271 <vector162>:
.globl vector162
vector162:
  pushl $0
80107271:	6a 00                	push   $0x0
  pushl $162
80107273:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107278:	e9 9c f3 ff ff       	jmp    80106619 <alltraps>

8010727d <vector163>:
.globl vector163
vector163:
  pushl $0
8010727d:	6a 00                	push   $0x0
  pushl $163
8010727f:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107284:	e9 90 f3 ff ff       	jmp    80106619 <alltraps>

80107289 <vector164>:
.globl vector164
vector164:
  pushl $0
80107289:	6a 00                	push   $0x0
  pushl $164
8010728b:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107290:	e9 84 f3 ff ff       	jmp    80106619 <alltraps>

80107295 <vector165>:
.globl vector165
vector165:
  pushl $0
80107295:	6a 00                	push   $0x0
  pushl $165
80107297:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
8010729c:	e9 78 f3 ff ff       	jmp    80106619 <alltraps>

801072a1 <vector166>:
.globl vector166
vector166:
  pushl $0
801072a1:	6a 00                	push   $0x0
  pushl $166
801072a3:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801072a8:	e9 6c f3 ff ff       	jmp    80106619 <alltraps>

801072ad <vector167>:
.globl vector167
vector167:
  pushl $0
801072ad:	6a 00                	push   $0x0
  pushl $167
801072af:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801072b4:	e9 60 f3 ff ff       	jmp    80106619 <alltraps>

801072b9 <vector168>:
.globl vector168
vector168:
  pushl $0
801072b9:	6a 00                	push   $0x0
  pushl $168
801072bb:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801072c0:	e9 54 f3 ff ff       	jmp    80106619 <alltraps>

801072c5 <vector169>:
.globl vector169
vector169:
  pushl $0
801072c5:	6a 00                	push   $0x0
  pushl $169
801072c7:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
801072cc:	e9 48 f3 ff ff       	jmp    80106619 <alltraps>

801072d1 <vector170>:
.globl vector170
vector170:
  pushl $0
801072d1:	6a 00                	push   $0x0
  pushl $170
801072d3:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801072d8:	e9 3c f3 ff ff       	jmp    80106619 <alltraps>

801072dd <vector171>:
.globl vector171
vector171:
  pushl $0
801072dd:	6a 00                	push   $0x0
  pushl $171
801072df:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801072e4:	e9 30 f3 ff ff       	jmp    80106619 <alltraps>

801072e9 <vector172>:
.globl vector172
vector172:
  pushl $0
801072e9:	6a 00                	push   $0x0
  pushl $172
801072eb:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801072f0:	e9 24 f3 ff ff       	jmp    80106619 <alltraps>

801072f5 <vector173>:
.globl vector173
vector173:
  pushl $0
801072f5:	6a 00                	push   $0x0
  pushl $173
801072f7:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801072fc:	e9 18 f3 ff ff       	jmp    80106619 <alltraps>

80107301 <vector174>:
.globl vector174
vector174:
  pushl $0
80107301:	6a 00                	push   $0x0
  pushl $174
80107303:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107308:	e9 0c f3 ff ff       	jmp    80106619 <alltraps>

8010730d <vector175>:
.globl vector175
vector175:
  pushl $0
8010730d:	6a 00                	push   $0x0
  pushl $175
8010730f:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107314:	e9 00 f3 ff ff       	jmp    80106619 <alltraps>

80107319 <vector176>:
.globl vector176
vector176:
  pushl $0
80107319:	6a 00                	push   $0x0
  pushl $176
8010731b:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107320:	e9 f4 f2 ff ff       	jmp    80106619 <alltraps>

80107325 <vector177>:
.globl vector177
vector177:
  pushl $0
80107325:	6a 00                	push   $0x0
  pushl $177
80107327:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
8010732c:	e9 e8 f2 ff ff       	jmp    80106619 <alltraps>

80107331 <vector178>:
.globl vector178
vector178:
  pushl $0
80107331:	6a 00                	push   $0x0
  pushl $178
80107333:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107338:	e9 dc f2 ff ff       	jmp    80106619 <alltraps>

8010733d <vector179>:
.globl vector179
vector179:
  pushl $0
8010733d:	6a 00                	push   $0x0
  pushl $179
8010733f:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107344:	e9 d0 f2 ff ff       	jmp    80106619 <alltraps>

80107349 <vector180>:
.globl vector180
vector180:
  pushl $0
80107349:	6a 00                	push   $0x0
  pushl $180
8010734b:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107350:	e9 c4 f2 ff ff       	jmp    80106619 <alltraps>

80107355 <vector181>:
.globl vector181
vector181:
  pushl $0
80107355:	6a 00                	push   $0x0
  pushl $181
80107357:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
8010735c:	e9 b8 f2 ff ff       	jmp    80106619 <alltraps>

80107361 <vector182>:
.globl vector182
vector182:
  pushl $0
80107361:	6a 00                	push   $0x0
  pushl $182
80107363:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107368:	e9 ac f2 ff ff       	jmp    80106619 <alltraps>

8010736d <vector183>:
.globl vector183
vector183:
  pushl $0
8010736d:	6a 00                	push   $0x0
  pushl $183
8010736f:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107374:	e9 a0 f2 ff ff       	jmp    80106619 <alltraps>

80107379 <vector184>:
.globl vector184
vector184:
  pushl $0
80107379:	6a 00                	push   $0x0
  pushl $184
8010737b:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107380:	e9 94 f2 ff ff       	jmp    80106619 <alltraps>

80107385 <vector185>:
.globl vector185
vector185:
  pushl $0
80107385:	6a 00                	push   $0x0
  pushl $185
80107387:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
8010738c:	e9 88 f2 ff ff       	jmp    80106619 <alltraps>

80107391 <vector186>:
.globl vector186
vector186:
  pushl $0
80107391:	6a 00                	push   $0x0
  pushl $186
80107393:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107398:	e9 7c f2 ff ff       	jmp    80106619 <alltraps>

8010739d <vector187>:
.globl vector187
vector187:
  pushl $0
8010739d:	6a 00                	push   $0x0
  pushl $187
8010739f:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801073a4:	e9 70 f2 ff ff       	jmp    80106619 <alltraps>

801073a9 <vector188>:
.globl vector188
vector188:
  pushl $0
801073a9:	6a 00                	push   $0x0
  pushl $188
801073ab:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801073b0:	e9 64 f2 ff ff       	jmp    80106619 <alltraps>

801073b5 <vector189>:
.globl vector189
vector189:
  pushl $0
801073b5:	6a 00                	push   $0x0
  pushl $189
801073b7:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801073bc:	e9 58 f2 ff ff       	jmp    80106619 <alltraps>

801073c1 <vector190>:
.globl vector190
vector190:
  pushl $0
801073c1:	6a 00                	push   $0x0
  pushl $190
801073c3:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801073c8:	e9 4c f2 ff ff       	jmp    80106619 <alltraps>

801073cd <vector191>:
.globl vector191
vector191:
  pushl $0
801073cd:	6a 00                	push   $0x0
  pushl $191
801073cf:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
801073d4:	e9 40 f2 ff ff       	jmp    80106619 <alltraps>

801073d9 <vector192>:
.globl vector192
vector192:
  pushl $0
801073d9:	6a 00                	push   $0x0
  pushl $192
801073db:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
801073e0:	e9 34 f2 ff ff       	jmp    80106619 <alltraps>

801073e5 <vector193>:
.globl vector193
vector193:
  pushl $0
801073e5:	6a 00                	push   $0x0
  pushl $193
801073e7:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801073ec:	e9 28 f2 ff ff       	jmp    80106619 <alltraps>

801073f1 <vector194>:
.globl vector194
vector194:
  pushl $0
801073f1:	6a 00                	push   $0x0
  pushl $194
801073f3:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801073f8:	e9 1c f2 ff ff       	jmp    80106619 <alltraps>

801073fd <vector195>:
.globl vector195
vector195:
  pushl $0
801073fd:	6a 00                	push   $0x0
  pushl $195
801073ff:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107404:	e9 10 f2 ff ff       	jmp    80106619 <alltraps>

80107409 <vector196>:
.globl vector196
vector196:
  pushl $0
80107409:	6a 00                	push   $0x0
  pushl $196
8010740b:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107410:	e9 04 f2 ff ff       	jmp    80106619 <alltraps>

80107415 <vector197>:
.globl vector197
vector197:
  pushl $0
80107415:	6a 00                	push   $0x0
  pushl $197
80107417:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
8010741c:	e9 f8 f1 ff ff       	jmp    80106619 <alltraps>

80107421 <vector198>:
.globl vector198
vector198:
  pushl $0
80107421:	6a 00                	push   $0x0
  pushl $198
80107423:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107428:	e9 ec f1 ff ff       	jmp    80106619 <alltraps>

8010742d <vector199>:
.globl vector199
vector199:
  pushl $0
8010742d:	6a 00                	push   $0x0
  pushl $199
8010742f:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107434:	e9 e0 f1 ff ff       	jmp    80106619 <alltraps>

80107439 <vector200>:
.globl vector200
vector200:
  pushl $0
80107439:	6a 00                	push   $0x0
  pushl $200
8010743b:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107440:	e9 d4 f1 ff ff       	jmp    80106619 <alltraps>

80107445 <vector201>:
.globl vector201
vector201:
  pushl $0
80107445:	6a 00                	push   $0x0
  pushl $201
80107447:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
8010744c:	e9 c8 f1 ff ff       	jmp    80106619 <alltraps>

80107451 <vector202>:
.globl vector202
vector202:
  pushl $0
80107451:	6a 00                	push   $0x0
  pushl $202
80107453:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107458:	e9 bc f1 ff ff       	jmp    80106619 <alltraps>

8010745d <vector203>:
.globl vector203
vector203:
  pushl $0
8010745d:	6a 00                	push   $0x0
  pushl $203
8010745f:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107464:	e9 b0 f1 ff ff       	jmp    80106619 <alltraps>

80107469 <vector204>:
.globl vector204
vector204:
  pushl $0
80107469:	6a 00                	push   $0x0
  pushl $204
8010746b:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107470:	e9 a4 f1 ff ff       	jmp    80106619 <alltraps>

80107475 <vector205>:
.globl vector205
vector205:
  pushl $0
80107475:	6a 00                	push   $0x0
  pushl $205
80107477:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
8010747c:	e9 98 f1 ff ff       	jmp    80106619 <alltraps>

80107481 <vector206>:
.globl vector206
vector206:
  pushl $0
80107481:	6a 00                	push   $0x0
  pushl $206
80107483:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107488:	e9 8c f1 ff ff       	jmp    80106619 <alltraps>

8010748d <vector207>:
.globl vector207
vector207:
  pushl $0
8010748d:	6a 00                	push   $0x0
  pushl $207
8010748f:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107494:	e9 80 f1 ff ff       	jmp    80106619 <alltraps>

80107499 <vector208>:
.globl vector208
vector208:
  pushl $0
80107499:	6a 00                	push   $0x0
  pushl $208
8010749b:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
801074a0:	e9 74 f1 ff ff       	jmp    80106619 <alltraps>

801074a5 <vector209>:
.globl vector209
vector209:
  pushl $0
801074a5:	6a 00                	push   $0x0
  pushl $209
801074a7:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
801074ac:	e9 68 f1 ff ff       	jmp    80106619 <alltraps>

801074b1 <vector210>:
.globl vector210
vector210:
  pushl $0
801074b1:	6a 00                	push   $0x0
  pushl $210
801074b3:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
801074b8:	e9 5c f1 ff ff       	jmp    80106619 <alltraps>

801074bd <vector211>:
.globl vector211
vector211:
  pushl $0
801074bd:	6a 00                	push   $0x0
  pushl $211
801074bf:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
801074c4:	e9 50 f1 ff ff       	jmp    80106619 <alltraps>

801074c9 <vector212>:
.globl vector212
vector212:
  pushl $0
801074c9:	6a 00                	push   $0x0
  pushl $212
801074cb:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
801074d0:	e9 44 f1 ff ff       	jmp    80106619 <alltraps>

801074d5 <vector213>:
.globl vector213
vector213:
  pushl $0
801074d5:	6a 00                	push   $0x0
  pushl $213
801074d7:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
801074dc:	e9 38 f1 ff ff       	jmp    80106619 <alltraps>

801074e1 <vector214>:
.globl vector214
vector214:
  pushl $0
801074e1:	6a 00                	push   $0x0
  pushl $214
801074e3:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
801074e8:	e9 2c f1 ff ff       	jmp    80106619 <alltraps>

801074ed <vector215>:
.globl vector215
vector215:
  pushl $0
801074ed:	6a 00                	push   $0x0
  pushl $215
801074ef:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
801074f4:	e9 20 f1 ff ff       	jmp    80106619 <alltraps>

801074f9 <vector216>:
.globl vector216
vector216:
  pushl $0
801074f9:	6a 00                	push   $0x0
  pushl $216
801074fb:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107500:	e9 14 f1 ff ff       	jmp    80106619 <alltraps>

80107505 <vector217>:
.globl vector217
vector217:
  pushl $0
80107505:	6a 00                	push   $0x0
  pushl $217
80107507:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
8010750c:	e9 08 f1 ff ff       	jmp    80106619 <alltraps>

80107511 <vector218>:
.globl vector218
vector218:
  pushl $0
80107511:	6a 00                	push   $0x0
  pushl $218
80107513:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107518:	e9 fc f0 ff ff       	jmp    80106619 <alltraps>

8010751d <vector219>:
.globl vector219
vector219:
  pushl $0
8010751d:	6a 00                	push   $0x0
  pushl $219
8010751f:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107524:	e9 f0 f0 ff ff       	jmp    80106619 <alltraps>

80107529 <vector220>:
.globl vector220
vector220:
  pushl $0
80107529:	6a 00                	push   $0x0
  pushl $220
8010752b:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107530:	e9 e4 f0 ff ff       	jmp    80106619 <alltraps>

80107535 <vector221>:
.globl vector221
vector221:
  pushl $0
80107535:	6a 00                	push   $0x0
  pushl $221
80107537:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
8010753c:	e9 d8 f0 ff ff       	jmp    80106619 <alltraps>

80107541 <vector222>:
.globl vector222
vector222:
  pushl $0
80107541:	6a 00                	push   $0x0
  pushl $222
80107543:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107548:	e9 cc f0 ff ff       	jmp    80106619 <alltraps>

8010754d <vector223>:
.globl vector223
vector223:
  pushl $0
8010754d:	6a 00                	push   $0x0
  pushl $223
8010754f:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107554:	e9 c0 f0 ff ff       	jmp    80106619 <alltraps>

80107559 <vector224>:
.globl vector224
vector224:
  pushl $0
80107559:	6a 00                	push   $0x0
  pushl $224
8010755b:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107560:	e9 b4 f0 ff ff       	jmp    80106619 <alltraps>

80107565 <vector225>:
.globl vector225
vector225:
  pushl $0
80107565:	6a 00                	push   $0x0
  pushl $225
80107567:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
8010756c:	e9 a8 f0 ff ff       	jmp    80106619 <alltraps>

80107571 <vector226>:
.globl vector226
vector226:
  pushl $0
80107571:	6a 00                	push   $0x0
  pushl $226
80107573:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107578:	e9 9c f0 ff ff       	jmp    80106619 <alltraps>

8010757d <vector227>:
.globl vector227
vector227:
  pushl $0
8010757d:	6a 00                	push   $0x0
  pushl $227
8010757f:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107584:	e9 90 f0 ff ff       	jmp    80106619 <alltraps>

80107589 <vector228>:
.globl vector228
vector228:
  pushl $0
80107589:	6a 00                	push   $0x0
  pushl $228
8010758b:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107590:	e9 84 f0 ff ff       	jmp    80106619 <alltraps>

80107595 <vector229>:
.globl vector229
vector229:
  pushl $0
80107595:	6a 00                	push   $0x0
  pushl $229
80107597:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
8010759c:	e9 78 f0 ff ff       	jmp    80106619 <alltraps>

801075a1 <vector230>:
.globl vector230
vector230:
  pushl $0
801075a1:	6a 00                	push   $0x0
  pushl $230
801075a3:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801075a8:	e9 6c f0 ff ff       	jmp    80106619 <alltraps>

801075ad <vector231>:
.globl vector231
vector231:
  pushl $0
801075ad:	6a 00                	push   $0x0
  pushl $231
801075af:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
801075b4:	e9 60 f0 ff ff       	jmp    80106619 <alltraps>

801075b9 <vector232>:
.globl vector232
vector232:
  pushl $0
801075b9:	6a 00                	push   $0x0
  pushl $232
801075bb:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
801075c0:	e9 54 f0 ff ff       	jmp    80106619 <alltraps>

801075c5 <vector233>:
.globl vector233
vector233:
  pushl $0
801075c5:	6a 00                	push   $0x0
  pushl $233
801075c7:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
801075cc:	e9 48 f0 ff ff       	jmp    80106619 <alltraps>

801075d1 <vector234>:
.globl vector234
vector234:
  pushl $0
801075d1:	6a 00                	push   $0x0
  pushl $234
801075d3:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
801075d8:	e9 3c f0 ff ff       	jmp    80106619 <alltraps>

801075dd <vector235>:
.globl vector235
vector235:
  pushl $0
801075dd:	6a 00                	push   $0x0
  pushl $235
801075df:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
801075e4:	e9 30 f0 ff ff       	jmp    80106619 <alltraps>

801075e9 <vector236>:
.globl vector236
vector236:
  pushl $0
801075e9:	6a 00                	push   $0x0
  pushl $236
801075eb:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
801075f0:	e9 24 f0 ff ff       	jmp    80106619 <alltraps>

801075f5 <vector237>:
.globl vector237
vector237:
  pushl $0
801075f5:	6a 00                	push   $0x0
  pushl $237
801075f7:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
801075fc:	e9 18 f0 ff ff       	jmp    80106619 <alltraps>

80107601 <vector238>:
.globl vector238
vector238:
  pushl $0
80107601:	6a 00                	push   $0x0
  pushl $238
80107603:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107608:	e9 0c f0 ff ff       	jmp    80106619 <alltraps>

8010760d <vector239>:
.globl vector239
vector239:
  pushl $0
8010760d:	6a 00                	push   $0x0
  pushl $239
8010760f:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107614:	e9 00 f0 ff ff       	jmp    80106619 <alltraps>

80107619 <vector240>:
.globl vector240
vector240:
  pushl $0
80107619:	6a 00                	push   $0x0
  pushl $240
8010761b:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107620:	e9 f4 ef ff ff       	jmp    80106619 <alltraps>

80107625 <vector241>:
.globl vector241
vector241:
  pushl $0
80107625:	6a 00                	push   $0x0
  pushl $241
80107627:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
8010762c:	e9 e8 ef ff ff       	jmp    80106619 <alltraps>

80107631 <vector242>:
.globl vector242
vector242:
  pushl $0
80107631:	6a 00                	push   $0x0
  pushl $242
80107633:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107638:	e9 dc ef ff ff       	jmp    80106619 <alltraps>

8010763d <vector243>:
.globl vector243
vector243:
  pushl $0
8010763d:	6a 00                	push   $0x0
  pushl $243
8010763f:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107644:	e9 d0 ef ff ff       	jmp    80106619 <alltraps>

80107649 <vector244>:
.globl vector244
vector244:
  pushl $0
80107649:	6a 00                	push   $0x0
  pushl $244
8010764b:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107650:	e9 c4 ef ff ff       	jmp    80106619 <alltraps>

80107655 <vector245>:
.globl vector245
vector245:
  pushl $0
80107655:	6a 00                	push   $0x0
  pushl $245
80107657:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
8010765c:	e9 b8 ef ff ff       	jmp    80106619 <alltraps>

80107661 <vector246>:
.globl vector246
vector246:
  pushl $0
80107661:	6a 00                	push   $0x0
  pushl $246
80107663:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107668:	e9 ac ef ff ff       	jmp    80106619 <alltraps>

8010766d <vector247>:
.globl vector247
vector247:
  pushl $0
8010766d:	6a 00                	push   $0x0
  pushl $247
8010766f:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107674:	e9 a0 ef ff ff       	jmp    80106619 <alltraps>

80107679 <vector248>:
.globl vector248
vector248:
  pushl $0
80107679:	6a 00                	push   $0x0
  pushl $248
8010767b:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107680:	e9 94 ef ff ff       	jmp    80106619 <alltraps>

80107685 <vector249>:
.globl vector249
vector249:
  pushl $0
80107685:	6a 00                	push   $0x0
  pushl $249
80107687:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
8010768c:	e9 88 ef ff ff       	jmp    80106619 <alltraps>

80107691 <vector250>:
.globl vector250
vector250:
  pushl $0
80107691:	6a 00                	push   $0x0
  pushl $250
80107693:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107698:	e9 7c ef ff ff       	jmp    80106619 <alltraps>

8010769d <vector251>:
.globl vector251
vector251:
  pushl $0
8010769d:	6a 00                	push   $0x0
  pushl $251
8010769f:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801076a4:	e9 70 ef ff ff       	jmp    80106619 <alltraps>

801076a9 <vector252>:
.globl vector252
vector252:
  pushl $0
801076a9:	6a 00                	push   $0x0
  pushl $252
801076ab:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801076b0:	e9 64 ef ff ff       	jmp    80106619 <alltraps>

801076b5 <vector253>:
.globl vector253
vector253:
  pushl $0
801076b5:	6a 00                	push   $0x0
  pushl $253
801076b7:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801076bc:	e9 58 ef ff ff       	jmp    80106619 <alltraps>

801076c1 <vector254>:
.globl vector254
vector254:
  pushl $0
801076c1:	6a 00                	push   $0x0
  pushl $254
801076c3:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
801076c8:	e9 4c ef ff ff       	jmp    80106619 <alltraps>

801076cd <vector255>:
.globl vector255
vector255:
  pushl $0
801076cd:	6a 00                	push   $0x0
  pushl $255
801076cf:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
801076d4:	e9 40 ef ff ff       	jmp    80106619 <alltraps>

801076d9 <lgdt>:
{
801076d9:	55                   	push   %ebp
801076da:	89 e5                	mov    %esp,%ebp
801076dc:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
801076df:	8b 45 0c             	mov    0xc(%ebp),%eax
801076e2:	83 e8 01             	sub    $0x1,%eax
801076e5:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801076e9:	8b 45 08             	mov    0x8(%ebp),%eax
801076ec:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801076f0:	8b 45 08             	mov    0x8(%ebp),%eax
801076f3:	c1 e8 10             	shr    $0x10,%eax
801076f6:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
801076fa:	8d 45 fa             	lea    -0x6(%ebp),%eax
801076fd:	0f 01 10             	lgdtl  (%eax)
}
80107700:	c9                   	leave  
80107701:	c3                   	ret    

80107702 <ltr>:
{
80107702:	55                   	push   %ebp
80107703:	89 e5                	mov    %esp,%ebp
80107705:	83 ec 04             	sub    $0x4,%esp
80107708:	8b 45 08             	mov    0x8(%ebp),%eax
8010770b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
8010770f:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107713:	0f 00 d8             	ltr    %ax
}
80107716:	c9                   	leave  
80107717:	c3                   	ret    

80107718 <lcr3>:

static inline void
lcr3(uint val)
{
80107718:	55                   	push   %ebp
80107719:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010771b:	8b 45 08             	mov    0x8(%ebp),%eax
8010771e:	0f 22 d8             	mov    %eax,%cr3
}
80107721:	5d                   	pop    %ebp
80107722:	c3                   	ret    

80107723 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107723:	55                   	push   %ebp
80107724:	89 e5                	mov    %esp,%ebp
80107726:	83 ec 28             	sub    $0x28,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpuid()];
80107729:	e8 9c c9 ff ff       	call   801040ca <cpuid>
8010772e:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80107734:	05 00 38 11 80       	add    $0x80113800,%eax
80107739:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
8010773c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010773f:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107745:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107748:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
8010774e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107751:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80107755:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107758:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010775c:	83 e2 f0             	and    $0xfffffff0,%edx
8010775f:	83 ca 0a             	or     $0xa,%edx
80107762:	88 50 7d             	mov    %dl,0x7d(%eax)
80107765:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107768:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010776c:	83 ca 10             	or     $0x10,%edx
8010776f:	88 50 7d             	mov    %dl,0x7d(%eax)
80107772:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107775:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107779:	83 e2 9f             	and    $0xffffff9f,%edx
8010777c:	88 50 7d             	mov    %dl,0x7d(%eax)
8010777f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107782:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107786:	83 ca 80             	or     $0xffffff80,%edx
80107789:	88 50 7d             	mov    %dl,0x7d(%eax)
8010778c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010778f:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107793:	83 ca 0f             	or     $0xf,%edx
80107796:	88 50 7e             	mov    %dl,0x7e(%eax)
80107799:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010779c:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801077a0:	83 e2 ef             	and    $0xffffffef,%edx
801077a3:	88 50 7e             	mov    %dl,0x7e(%eax)
801077a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077a9:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801077ad:	83 e2 df             	and    $0xffffffdf,%edx
801077b0:	88 50 7e             	mov    %dl,0x7e(%eax)
801077b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077b6:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801077ba:	83 ca 40             	or     $0x40,%edx
801077bd:	88 50 7e             	mov    %dl,0x7e(%eax)
801077c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077c3:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801077c7:	83 ca 80             	or     $0xffffff80,%edx
801077ca:	88 50 7e             	mov    %dl,0x7e(%eax)
801077cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077d0:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801077d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077d7:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801077de:	ff ff 
801077e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077e3:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801077ea:	00 00 
801077ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ef:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801077f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077f9:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107800:	83 e2 f0             	and    $0xfffffff0,%edx
80107803:	83 ca 02             	or     $0x2,%edx
80107806:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010780c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010780f:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107816:	83 ca 10             	or     $0x10,%edx
80107819:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010781f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107822:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107829:	83 e2 9f             	and    $0xffffff9f,%edx
8010782c:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107832:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107835:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010783c:	83 ca 80             	or     $0xffffff80,%edx
8010783f:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107845:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107848:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010784f:	83 ca 0f             	or     $0xf,%edx
80107852:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107858:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010785b:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107862:	83 e2 ef             	and    $0xffffffef,%edx
80107865:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010786b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010786e:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107875:	83 e2 df             	and    $0xffffffdf,%edx
80107878:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010787e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107881:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107888:	83 ca 40             	or     $0x40,%edx
8010788b:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107891:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107894:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010789b:	83 ca 80             	or     $0xffffff80,%edx
8010789e:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801078a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078a7:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801078ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078b1:	66 c7 80 88 00 00 00 	movw   $0xffff,0x88(%eax)
801078b8:	ff ff 
801078ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078bd:	66 c7 80 8a 00 00 00 	movw   $0x0,0x8a(%eax)
801078c4:	00 00 
801078c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078c9:	c6 80 8c 00 00 00 00 	movb   $0x0,0x8c(%eax)
801078d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078d3:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
801078da:	83 e2 f0             	and    $0xfffffff0,%edx
801078dd:	83 ca 0a             	or     $0xa,%edx
801078e0:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
801078e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078e9:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
801078f0:	83 ca 10             	or     $0x10,%edx
801078f3:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
801078f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078fc:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
80107903:	83 ca 60             	or     $0x60,%edx
80107906:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
8010790c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010790f:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
80107916:	83 ca 80             	or     $0xffffff80,%edx
80107919:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
8010791f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107922:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
80107929:	83 ca 0f             	or     $0xf,%edx
8010792c:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
80107932:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107935:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
8010793c:	83 e2 ef             	and    $0xffffffef,%edx
8010793f:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
80107945:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107948:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
8010794f:	83 e2 df             	and    $0xffffffdf,%edx
80107952:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
80107958:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010795b:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
80107962:	83 ca 40             	or     $0x40,%edx
80107965:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
8010796b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010796e:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
80107975:	83 ca 80             	or     $0xffffff80,%edx
80107978:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
8010797e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107981:	c6 80 8f 00 00 00 00 	movb   $0x0,0x8f(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80107988:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010798b:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80107992:	ff ff 
80107994:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107997:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
8010799e:	00 00 
801079a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079a3:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
801079aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ad:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801079b4:	83 e2 f0             	and    $0xfffffff0,%edx
801079b7:	83 ca 02             	or     $0x2,%edx
801079ba:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801079c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079c3:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801079ca:	83 ca 10             	or     $0x10,%edx
801079cd:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801079d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079d6:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801079dd:	83 ca 60             	or     $0x60,%edx
801079e0:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801079e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079e9:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801079f0:	83 ca 80             	or     $0xffffff80,%edx
801079f3:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801079f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079fc:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107a03:	83 ca 0f             	or     $0xf,%edx
80107a06:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107a0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a0f:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107a16:	83 e2 ef             	and    $0xffffffef,%edx
80107a19:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107a1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a22:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107a29:	83 e2 df             	and    $0xffffffdf,%edx
80107a2c:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107a32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a35:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107a3c:	83 ca 40             	or     $0x40,%edx
80107a3f:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107a45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a48:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107a4f:	83 ca 80             	or     $0xffffff80,%edx
80107a52:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107a58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a5b:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80107a62:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a65:	83 c0 70             	add    $0x70,%eax
80107a68:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80107a6f:	00 
80107a70:	89 04 24             	mov    %eax,(%esp)
80107a73:	e8 61 fc ff ff       	call   801076d9 <lgdt>
}
80107a78:	c9                   	leave  
80107a79:	c3                   	ret    

80107a7a <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107a7a:	55                   	push   %ebp
80107a7b:	89 e5                	mov    %esp,%ebp
80107a7d:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107a80:	8b 45 0c             	mov    0xc(%ebp),%eax
80107a83:	c1 e8 16             	shr    $0x16,%eax
80107a86:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107a8d:	8b 45 08             	mov    0x8(%ebp),%eax
80107a90:	01 d0                	add    %edx,%eax
80107a92:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107a95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107a98:	8b 00                	mov    (%eax),%eax
80107a9a:	83 e0 01             	and    $0x1,%eax
80107a9d:	85 c0                	test   %eax,%eax
80107a9f:	74 14                	je     80107ab5 <walkpgdir+0x3b>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80107aa1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107aa4:	8b 00                	mov    (%eax),%eax
80107aa6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107aab:	05 00 00 00 80       	add    $0x80000000,%eax
80107ab0:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107ab3:	eb 48                	jmp    80107afd <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107ab5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107ab9:	74 0e                	je     80107ac9 <walkpgdir+0x4f>
80107abb:	e8 e9 b0 ff ff       	call   80102ba9 <kalloc>
80107ac0:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107ac3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107ac7:	75 07                	jne    80107ad0 <walkpgdir+0x56>
      return 0;
80107ac9:	b8 00 00 00 00       	mov    $0x0,%eax
80107ace:	eb 44                	jmp    80107b14 <walkpgdir+0x9a>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107ad0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107ad7:	00 
80107ad8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107adf:	00 
80107ae0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ae3:	89 04 24             	mov    %eax,(%esp)
80107ae6:	e8 67 d7 ff ff       	call   80105252 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80107aeb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aee:	05 00 00 00 80       	add    $0x80000000,%eax
80107af3:	83 c8 07             	or     $0x7,%eax
80107af6:	89 c2                	mov    %eax,%edx
80107af8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107afb:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107afd:	8b 45 0c             	mov    0xc(%ebp),%eax
80107b00:	c1 e8 0c             	shr    $0xc,%eax
80107b03:	25 ff 03 00 00       	and    $0x3ff,%eax
80107b08:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107b0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b12:	01 d0                	add    %edx,%eax
}
80107b14:	c9                   	leave  
80107b15:	c3                   	ret    

80107b16 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107b16:	55                   	push   %ebp
80107b17:	89 e5                	mov    %esp,%ebp
80107b19:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80107b1c:	8b 45 0c             	mov    0xc(%ebp),%eax
80107b1f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107b24:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107b27:	8b 55 0c             	mov    0xc(%ebp),%edx
80107b2a:	8b 45 10             	mov    0x10(%ebp),%eax
80107b2d:	01 d0                	add    %edx,%eax
80107b2f:	83 e8 01             	sub    $0x1,%eax
80107b32:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107b37:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107b3a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80107b41:	00 
80107b42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b45:	89 44 24 04          	mov    %eax,0x4(%esp)
80107b49:	8b 45 08             	mov    0x8(%ebp),%eax
80107b4c:	89 04 24             	mov    %eax,(%esp)
80107b4f:	e8 26 ff ff ff       	call   80107a7a <walkpgdir>
80107b54:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107b57:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107b5b:	75 07                	jne    80107b64 <mappages+0x4e>
      return -1;
80107b5d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107b62:	eb 48                	jmp    80107bac <mappages+0x96>
    if(*pte & PTE_P)
80107b64:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107b67:	8b 00                	mov    (%eax),%eax
80107b69:	83 e0 01             	and    $0x1,%eax
80107b6c:	85 c0                	test   %eax,%eax
80107b6e:	74 0c                	je     80107b7c <mappages+0x66>
      panic("remap");
80107b70:	c7 04 24 8c 8a 10 80 	movl   $0x80108a8c,(%esp)
80107b77:	e8 e6 89 ff ff       	call   80100562 <panic>
    *pte = pa | perm | PTE_P;
80107b7c:	8b 45 18             	mov    0x18(%ebp),%eax
80107b7f:	0b 45 14             	or     0x14(%ebp),%eax
80107b82:	83 c8 01             	or     $0x1,%eax
80107b85:	89 c2                	mov    %eax,%edx
80107b87:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107b8a:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107b8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b8f:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107b92:	75 08                	jne    80107b9c <mappages+0x86>
      break;
80107b94:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107b95:	b8 00 00 00 00       	mov    $0x0,%eax
80107b9a:	eb 10                	jmp    80107bac <mappages+0x96>
    a += PGSIZE;
80107b9c:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107ba3:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107baa:	eb 8e                	jmp    80107b3a <mappages+0x24>
}
80107bac:	c9                   	leave  
80107bad:	c3                   	ret    

80107bae <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80107bae:	55                   	push   %ebp
80107baf:	89 e5                	mov    %esp,%ebp
80107bb1:	53                   	push   %ebx
80107bb2:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107bb5:	e8 ef af ff ff       	call   80102ba9 <kalloc>
80107bba:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107bbd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107bc1:	75 0a                	jne    80107bcd <setupkvm+0x1f>
    return 0;
80107bc3:	b8 00 00 00 00       	mov    $0x0,%eax
80107bc8:	e9 84 00 00 00       	jmp    80107c51 <setupkvm+0xa3>
  memset(pgdir, 0, PGSIZE);
80107bcd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107bd4:	00 
80107bd5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107bdc:	00 
80107bdd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107be0:	89 04 24             	mov    %eax,(%esp)
80107be3:	e8 6a d6 ff ff       	call   80105252 <memset>
  if (P2V(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107be8:	c7 45 f4 80 b4 10 80 	movl   $0x8010b480,-0xc(%ebp)
80107bef:	eb 54                	jmp    80107c45 <setupkvm+0x97>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80107bf1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bf4:	8b 48 0c             	mov    0xc(%eax),%ecx
80107bf7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bfa:	8b 50 04             	mov    0x4(%eax),%edx
80107bfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c00:	8b 58 08             	mov    0x8(%eax),%ebx
80107c03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c06:	8b 40 04             	mov    0x4(%eax),%eax
80107c09:	29 c3                	sub    %eax,%ebx
80107c0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c0e:	8b 00                	mov    (%eax),%eax
80107c10:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107c14:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107c18:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107c1c:	89 44 24 04          	mov    %eax,0x4(%esp)
80107c20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c23:	89 04 24             	mov    %eax,(%esp)
80107c26:	e8 eb fe ff ff       	call   80107b16 <mappages>
80107c2b:	85 c0                	test   %eax,%eax
80107c2d:	79 12                	jns    80107c41 <setupkvm+0x93>
                (uint)k->phys_start, k->perm) < 0) {
      freevm(pgdir);
80107c2f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c32:	89 04 24             	mov    %eax,(%esp)
80107c35:	e8 26 05 00 00       	call   80108160 <freevm>
      return 0;
80107c3a:	b8 00 00 00 00       	mov    $0x0,%eax
80107c3f:	eb 10                	jmp    80107c51 <setupkvm+0xa3>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107c41:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107c45:	81 7d f4 c0 b4 10 80 	cmpl   $0x8010b4c0,-0xc(%ebp)
80107c4c:	72 a3                	jb     80107bf1 <setupkvm+0x43>
    }
  return pgdir;
80107c4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107c51:	83 c4 34             	add    $0x34,%esp
80107c54:	5b                   	pop    %ebx
80107c55:	5d                   	pop    %ebp
80107c56:	c3                   	ret    

80107c57 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107c57:	55                   	push   %ebp
80107c58:	89 e5                	mov    %esp,%ebp
80107c5a:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107c5d:	e8 4c ff ff ff       	call   80107bae <setupkvm>
80107c62:	a3 24 67 11 80       	mov    %eax,0x80116724
  switchkvm();
80107c67:	e8 02 00 00 00       	call   80107c6e <switchkvm>
}
80107c6c:	c9                   	leave  
80107c6d:	c3                   	ret    

80107c6e <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107c6e:	55                   	push   %ebp
80107c6f:	89 e5                	mov    %esp,%ebp
80107c71:	83 ec 04             	sub    $0x4,%esp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80107c74:	a1 24 67 11 80       	mov    0x80116724,%eax
80107c79:	05 00 00 00 80       	add    $0x80000000,%eax
80107c7e:	89 04 24             	mov    %eax,(%esp)
80107c81:	e8 92 fa ff ff       	call   80107718 <lcr3>
}
80107c86:	c9                   	leave  
80107c87:	c3                   	ret    

80107c88 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107c88:	55                   	push   %ebp
80107c89:	89 e5                	mov    %esp,%ebp
80107c8b:	57                   	push   %edi
80107c8c:	56                   	push   %esi
80107c8d:	53                   	push   %ebx
80107c8e:	83 ec 1c             	sub    $0x1c,%esp
  if(p == 0)
80107c91:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80107c95:	75 0c                	jne    80107ca3 <switchuvm+0x1b>
    panic("switchuvm: no process");
80107c97:	c7 04 24 92 8a 10 80 	movl   $0x80108a92,(%esp)
80107c9e:	e8 bf 88 ff ff       	call   80100562 <panic>
  if(p->kstack == 0)
80107ca3:	8b 45 08             	mov    0x8(%ebp),%eax
80107ca6:	8b 40 08             	mov    0x8(%eax),%eax
80107ca9:	85 c0                	test   %eax,%eax
80107cab:	75 0c                	jne    80107cb9 <switchuvm+0x31>
    panic("switchuvm: no kstack");
80107cad:	c7 04 24 a8 8a 10 80 	movl   $0x80108aa8,(%esp)
80107cb4:	e8 a9 88 ff ff       	call   80100562 <panic>
  if(p->pgdir == 0)
80107cb9:	8b 45 08             	mov    0x8(%ebp),%eax
80107cbc:	8b 40 04             	mov    0x4(%eax),%eax
80107cbf:	85 c0                	test   %eax,%eax
80107cc1:	75 0c                	jne    80107ccf <switchuvm+0x47>
    panic("switchuvm: no pgdir");
80107cc3:	c7 04 24 bd 8a 10 80 	movl   $0x80108abd,(%esp)
80107cca:	e8 93 88 ff ff       	call   80100562 <panic>

  pushcli();
80107ccf:	e8 79 d4 ff ff       	call   8010514d <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80107cd4:	e8 12 c4 ff ff       	call   801040eb <mycpu>
80107cd9:	89 c3                	mov    %eax,%ebx
80107cdb:	e8 0b c4 ff ff       	call   801040eb <mycpu>
80107ce0:	83 c0 08             	add    $0x8,%eax
80107ce3:	89 c7                	mov    %eax,%edi
80107ce5:	e8 01 c4 ff ff       	call   801040eb <mycpu>
80107cea:	83 c0 08             	add    $0x8,%eax
80107ced:	c1 e8 10             	shr    $0x10,%eax
80107cf0:	89 c6                	mov    %eax,%esi
80107cf2:	e8 f4 c3 ff ff       	call   801040eb <mycpu>
80107cf7:	83 c0 08             	add    $0x8,%eax
80107cfa:	c1 e8 18             	shr    $0x18,%eax
80107cfd:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80107d04:	67 00 
80107d06:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80107d0d:	89 f1                	mov    %esi,%ecx
80107d0f:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80107d15:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80107d1c:	83 e2 f0             	and    $0xfffffff0,%edx
80107d1f:	83 ca 09             	or     $0x9,%edx
80107d22:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80107d28:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80107d2f:	83 ca 10             	or     $0x10,%edx
80107d32:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80107d38:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80107d3f:	83 e2 9f             	and    $0xffffff9f,%edx
80107d42:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80107d48:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80107d4f:	83 ca 80             	or     $0xffffff80,%edx
80107d52:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80107d58:	0f b6 93 9e 00 00 00 	movzbl 0x9e(%ebx),%edx
80107d5f:	83 e2 f0             	and    $0xfffffff0,%edx
80107d62:	88 93 9e 00 00 00    	mov    %dl,0x9e(%ebx)
80107d68:	0f b6 93 9e 00 00 00 	movzbl 0x9e(%ebx),%edx
80107d6f:	83 e2 ef             	and    $0xffffffef,%edx
80107d72:	88 93 9e 00 00 00    	mov    %dl,0x9e(%ebx)
80107d78:	0f b6 93 9e 00 00 00 	movzbl 0x9e(%ebx),%edx
80107d7f:	83 e2 df             	and    $0xffffffdf,%edx
80107d82:	88 93 9e 00 00 00    	mov    %dl,0x9e(%ebx)
80107d88:	0f b6 93 9e 00 00 00 	movzbl 0x9e(%ebx),%edx
80107d8f:	83 ca 40             	or     $0x40,%edx
80107d92:	88 93 9e 00 00 00    	mov    %dl,0x9e(%ebx)
80107d98:	0f b6 93 9e 00 00 00 	movzbl 0x9e(%ebx),%edx
80107d9f:	83 e2 7f             	and    $0x7f,%edx
80107da2:	88 93 9e 00 00 00    	mov    %dl,0x9e(%ebx)
80107da8:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80107dae:	e8 38 c3 ff ff       	call   801040eb <mycpu>
80107db3:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107dba:	83 e2 ef             	and    $0xffffffef,%edx
80107dbd:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80107dc3:	e8 23 c3 ff ff       	call   801040eb <mycpu>
80107dc8:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80107dce:	e8 18 c3 ff ff       	call   801040eb <mycpu>
80107dd3:	8b 55 08             	mov    0x8(%ebp),%edx
80107dd6:	8b 52 08             	mov    0x8(%edx),%edx
80107dd9:	81 c2 00 10 00 00    	add    $0x1000,%edx
80107ddf:	89 50 0c             	mov    %edx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80107de2:	e8 04 c3 ff ff       	call   801040eb <mycpu>
80107de7:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  ltr(SEG_TSS << 3);
80107ded:	c7 04 24 28 00 00 00 	movl   $0x28,(%esp)
80107df4:	e8 09 f9 ff ff       	call   80107702 <ltr>
  lcr3(V2P(p->pgdir));  // switch to process's address space
80107df9:	8b 45 08             	mov    0x8(%ebp),%eax
80107dfc:	8b 40 04             	mov    0x4(%eax),%eax
80107dff:	05 00 00 00 80       	add    $0x80000000,%eax
80107e04:	89 04 24             	mov    %eax,(%esp)
80107e07:	e8 0c f9 ff ff       	call   80107718 <lcr3>
  popcli();
80107e0c:	e8 88 d3 ff ff       	call   80105199 <popcli>
}
80107e11:	83 c4 1c             	add    $0x1c,%esp
80107e14:	5b                   	pop    %ebx
80107e15:	5e                   	pop    %esi
80107e16:	5f                   	pop    %edi
80107e17:	5d                   	pop    %ebp
80107e18:	c3                   	ret    

80107e19 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107e19:	55                   	push   %ebp
80107e1a:	89 e5                	mov    %esp,%ebp
80107e1c:	83 ec 38             	sub    $0x38,%esp
  char *mem;

  if(sz >= PGSIZE)
80107e1f:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107e26:	76 0c                	jbe    80107e34 <inituvm+0x1b>
    panic("inituvm: more than a page");
80107e28:	c7 04 24 d1 8a 10 80 	movl   $0x80108ad1,(%esp)
80107e2f:	e8 2e 87 ff ff       	call   80100562 <panic>
  mem = kalloc();
80107e34:	e8 70 ad ff ff       	call   80102ba9 <kalloc>
80107e39:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107e3c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107e43:	00 
80107e44:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107e4b:	00 
80107e4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e4f:	89 04 24             	mov    %eax,(%esp)
80107e52:	e8 fb d3 ff ff       	call   80105252 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
80107e57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e5a:	05 00 00 00 80       	add    $0x80000000,%eax
80107e5f:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107e66:	00 
80107e67:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107e6b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107e72:	00 
80107e73:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107e7a:	00 
80107e7b:	8b 45 08             	mov    0x8(%ebp),%eax
80107e7e:	89 04 24             	mov    %eax,(%esp)
80107e81:	e8 90 fc ff ff       	call   80107b16 <mappages>
  memmove(mem, init, sz);
80107e86:	8b 45 10             	mov    0x10(%ebp),%eax
80107e89:	89 44 24 08          	mov    %eax,0x8(%esp)
80107e8d:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e90:	89 44 24 04          	mov    %eax,0x4(%esp)
80107e94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e97:	89 04 24             	mov    %eax,(%esp)
80107e9a:	e8 82 d4 ff ff       	call   80105321 <memmove>
}
80107e9f:	c9                   	leave  
80107ea0:	c3                   	ret    

80107ea1 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80107ea1:	55                   	push   %ebp
80107ea2:	89 e5                	mov    %esp,%ebp
80107ea4:	83 ec 28             	sub    $0x28,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80107ea7:	8b 45 0c             	mov    0xc(%ebp),%eax
80107eaa:	25 ff 0f 00 00       	and    $0xfff,%eax
80107eaf:	85 c0                	test   %eax,%eax
80107eb1:	74 0c                	je     80107ebf <loaduvm+0x1e>
    panic("loaduvm: addr must be page aligned");
80107eb3:	c7 04 24 ec 8a 10 80 	movl   $0x80108aec,(%esp)
80107eba:	e8 a3 86 ff ff       	call   80100562 <panic>
  for(i = 0; i < sz; i += PGSIZE){
80107ebf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107ec6:	e9 a6 00 00 00       	jmp    80107f71 <loaduvm+0xd0>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80107ecb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ece:	8b 55 0c             	mov    0xc(%ebp),%edx
80107ed1:	01 d0                	add    %edx,%eax
80107ed3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107eda:	00 
80107edb:	89 44 24 04          	mov    %eax,0x4(%esp)
80107edf:	8b 45 08             	mov    0x8(%ebp),%eax
80107ee2:	89 04 24             	mov    %eax,(%esp)
80107ee5:	e8 90 fb ff ff       	call   80107a7a <walkpgdir>
80107eea:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107eed:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107ef1:	75 0c                	jne    80107eff <loaduvm+0x5e>
      panic("loaduvm: address should exist");
80107ef3:	c7 04 24 0f 8b 10 80 	movl   $0x80108b0f,(%esp)
80107efa:	e8 63 86 ff ff       	call   80100562 <panic>
    pa = PTE_ADDR(*pte);
80107eff:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107f02:	8b 00                	mov    (%eax),%eax
80107f04:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f09:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80107f0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f0f:	8b 55 18             	mov    0x18(%ebp),%edx
80107f12:	29 c2                	sub    %eax,%edx
80107f14:	89 d0                	mov    %edx,%eax
80107f16:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80107f1b:	77 0f                	ja     80107f2c <loaduvm+0x8b>
      n = sz - i;
80107f1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f20:	8b 55 18             	mov    0x18(%ebp),%edx
80107f23:	29 c2                	sub    %eax,%edx
80107f25:	89 d0                	mov    %edx,%eax
80107f27:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107f2a:	eb 07                	jmp    80107f33 <loaduvm+0x92>
    else
      n = PGSIZE;
80107f2c:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, P2V(pa), offset+i, n) != n)
80107f33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f36:	8b 55 14             	mov    0x14(%ebp),%edx
80107f39:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80107f3c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107f3f:	05 00 00 00 80       	add    $0x80000000,%eax
80107f44:	8b 55 f0             	mov    -0x10(%ebp),%edx
80107f47:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107f4b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107f4f:	89 44 24 04          	mov    %eax,0x4(%esp)
80107f53:	8b 45 10             	mov    0x10(%ebp),%eax
80107f56:	89 04 24             	mov    %eax,(%esp)
80107f59:	e8 9c 9e ff ff       	call   80101dfa <readi>
80107f5e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107f61:	74 07                	je     80107f6a <loaduvm+0xc9>
      return -1;
80107f63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107f68:	eb 18                	jmp    80107f82 <loaduvm+0xe1>
  for(i = 0; i < sz; i += PGSIZE){
80107f6a:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107f71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f74:	3b 45 18             	cmp    0x18(%ebp),%eax
80107f77:	0f 82 4e ff ff ff    	jb     80107ecb <loaduvm+0x2a>
  }
  return 0;
80107f7d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107f82:	c9                   	leave  
80107f83:	c3                   	ret    

80107f84 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107f84:	55                   	push   %ebp
80107f85:	89 e5                	mov    %esp,%ebp
80107f87:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80107f8a:	8b 45 10             	mov    0x10(%ebp),%eax
80107f8d:	85 c0                	test   %eax,%eax
80107f8f:	79 0a                	jns    80107f9b <allocuvm+0x17>
    return 0;
80107f91:	b8 00 00 00 00       	mov    $0x0,%eax
80107f96:	e9 fd 00 00 00       	jmp    80108098 <allocuvm+0x114>
  if(newsz < oldsz)
80107f9b:	8b 45 10             	mov    0x10(%ebp),%eax
80107f9e:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107fa1:	73 08                	jae    80107fab <allocuvm+0x27>
    return oldsz;
80107fa3:	8b 45 0c             	mov    0xc(%ebp),%eax
80107fa6:	e9 ed 00 00 00       	jmp    80108098 <allocuvm+0x114>

  a = PGROUNDUP(oldsz);
80107fab:	8b 45 0c             	mov    0xc(%ebp),%eax
80107fae:	05 ff 0f 00 00       	add    $0xfff,%eax
80107fb3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107fb8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80107fbb:	e9 c9 00 00 00       	jmp    80108089 <allocuvm+0x105>
    mem = kalloc();
80107fc0:	e8 e4 ab ff ff       	call   80102ba9 <kalloc>
80107fc5:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80107fc8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107fcc:	75 2f                	jne    80107ffd <allocuvm+0x79>
      cprintf("allocuvm out of memory\n");
80107fce:	c7 04 24 2d 8b 10 80 	movl   $0x80108b2d,(%esp)
80107fd5:	e8 ee 83 ff ff       	call   801003c8 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80107fda:	8b 45 0c             	mov    0xc(%ebp),%eax
80107fdd:	89 44 24 08          	mov    %eax,0x8(%esp)
80107fe1:	8b 45 10             	mov    0x10(%ebp),%eax
80107fe4:	89 44 24 04          	mov    %eax,0x4(%esp)
80107fe8:	8b 45 08             	mov    0x8(%ebp),%eax
80107feb:	89 04 24             	mov    %eax,(%esp)
80107fee:	e8 a7 00 00 00       	call   8010809a <deallocuvm>
      return 0;
80107ff3:	b8 00 00 00 00       	mov    $0x0,%eax
80107ff8:	e9 9b 00 00 00       	jmp    80108098 <allocuvm+0x114>
    }
    memset(mem, 0, PGSIZE);
80107ffd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108004:	00 
80108005:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010800c:	00 
8010800d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108010:	89 04 24             	mov    %eax,(%esp)
80108013:	e8 3a d2 ff ff       	call   80105252 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
80108018:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010801b:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
80108021:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108024:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010802b:	00 
8010802c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108030:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108037:	00 
80108038:	89 44 24 04          	mov    %eax,0x4(%esp)
8010803c:	8b 45 08             	mov    0x8(%ebp),%eax
8010803f:	89 04 24             	mov    %eax,(%esp)
80108042:	e8 cf fa ff ff       	call   80107b16 <mappages>
80108047:	85 c0                	test   %eax,%eax
80108049:	79 37                	jns    80108082 <allocuvm+0xfe>
      cprintf("allocuvm out of memory (2)\n");
8010804b:	c7 04 24 45 8b 10 80 	movl   $0x80108b45,(%esp)
80108052:	e8 71 83 ff ff       	call   801003c8 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108057:	8b 45 0c             	mov    0xc(%ebp),%eax
8010805a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010805e:	8b 45 10             	mov    0x10(%ebp),%eax
80108061:	89 44 24 04          	mov    %eax,0x4(%esp)
80108065:	8b 45 08             	mov    0x8(%ebp),%eax
80108068:	89 04 24             	mov    %eax,(%esp)
8010806b:	e8 2a 00 00 00       	call   8010809a <deallocuvm>
      kfree(mem);
80108070:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108073:	89 04 24             	mov    %eax,(%esp)
80108076:	e8 98 aa ff ff       	call   80102b13 <kfree>
      return 0;
8010807b:	b8 00 00 00 00       	mov    $0x0,%eax
80108080:	eb 16                	jmp    80108098 <allocuvm+0x114>
  for(; a < newsz; a += PGSIZE){
80108082:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108089:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010808c:	3b 45 10             	cmp    0x10(%ebp),%eax
8010808f:	0f 82 2b ff ff ff    	jb     80107fc0 <allocuvm+0x3c>
    }
  }
  return newsz;
80108095:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108098:	c9                   	leave  
80108099:	c3                   	ret    

8010809a <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010809a:	55                   	push   %ebp
8010809b:	89 e5                	mov    %esp,%ebp
8010809d:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801080a0:	8b 45 10             	mov    0x10(%ebp),%eax
801080a3:	3b 45 0c             	cmp    0xc(%ebp),%eax
801080a6:	72 08                	jb     801080b0 <deallocuvm+0x16>
    return oldsz;
801080a8:	8b 45 0c             	mov    0xc(%ebp),%eax
801080ab:	e9 ae 00 00 00       	jmp    8010815e <deallocuvm+0xc4>

  a = PGROUNDUP(newsz);
801080b0:	8b 45 10             	mov    0x10(%ebp),%eax
801080b3:	05 ff 0f 00 00       	add    $0xfff,%eax
801080b8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801080bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
801080c0:	e9 8a 00 00 00       	jmp    8010814f <deallocuvm+0xb5>
    pte = walkpgdir(pgdir, (char*)a, 0);
801080c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080c8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801080cf:	00 
801080d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801080d4:	8b 45 08             	mov    0x8(%ebp),%eax
801080d7:	89 04 24             	mov    %eax,(%esp)
801080da:	e8 9b f9 ff ff       	call   80107a7a <walkpgdir>
801080df:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
801080e2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801080e6:	75 16                	jne    801080fe <deallocuvm+0x64>
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
801080e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080eb:	c1 e8 16             	shr    $0x16,%eax
801080ee:	83 c0 01             	add    $0x1,%eax
801080f1:	c1 e0 16             	shl    $0x16,%eax
801080f4:	2d 00 10 00 00       	sub    $0x1000,%eax
801080f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801080fc:	eb 4a                	jmp    80108148 <deallocuvm+0xae>
    else if((*pte & PTE_P) != 0){
801080fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108101:	8b 00                	mov    (%eax),%eax
80108103:	83 e0 01             	and    $0x1,%eax
80108106:	85 c0                	test   %eax,%eax
80108108:	74 3e                	je     80108148 <deallocuvm+0xae>
      pa = PTE_ADDR(*pte);
8010810a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010810d:	8b 00                	mov    (%eax),%eax
8010810f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108114:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108117:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010811b:	75 0c                	jne    80108129 <deallocuvm+0x8f>
        panic("kfree");
8010811d:	c7 04 24 61 8b 10 80 	movl   $0x80108b61,(%esp)
80108124:	e8 39 84 ff ff       	call   80100562 <panic>
      char *v = P2V(pa);
80108129:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010812c:	05 00 00 00 80       	add    $0x80000000,%eax
80108131:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108134:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108137:	89 04 24             	mov    %eax,(%esp)
8010813a:	e8 d4 a9 ff ff       	call   80102b13 <kfree>
      *pte = 0;
8010813f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108142:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  for(; a  < oldsz; a += PGSIZE){
80108148:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010814f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108152:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108155:	0f 82 6a ff ff ff    	jb     801080c5 <deallocuvm+0x2b>
    }
  }
  return newsz;
8010815b:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010815e:	c9                   	leave  
8010815f:	c3                   	ret    

80108160 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108160:	55                   	push   %ebp
80108161:	89 e5                	mov    %esp,%ebp
80108163:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108166:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010816a:	75 0c                	jne    80108178 <freevm+0x18>
    panic("freevm: no pgdir");
8010816c:	c7 04 24 67 8b 10 80 	movl   $0x80108b67,(%esp)
80108173:	e8 ea 83 ff ff       	call   80100562 <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80108178:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010817f:	00 
80108180:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108187:	80 
80108188:	8b 45 08             	mov    0x8(%ebp),%eax
8010818b:	89 04 24             	mov    %eax,(%esp)
8010818e:	e8 07 ff ff ff       	call   8010809a <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108193:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010819a:	eb 45                	jmp    801081e1 <freevm+0x81>
    if(pgdir[i] & PTE_P){
8010819c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010819f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801081a6:	8b 45 08             	mov    0x8(%ebp),%eax
801081a9:	01 d0                	add    %edx,%eax
801081ab:	8b 00                	mov    (%eax),%eax
801081ad:	83 e0 01             	and    $0x1,%eax
801081b0:	85 c0                	test   %eax,%eax
801081b2:	74 29                	je     801081dd <freevm+0x7d>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801081b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081b7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801081be:	8b 45 08             	mov    0x8(%ebp),%eax
801081c1:	01 d0                	add    %edx,%eax
801081c3:	8b 00                	mov    (%eax),%eax
801081c5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801081ca:	05 00 00 00 80       	add    $0x80000000,%eax
801081cf:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
801081d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801081d5:	89 04 24             	mov    %eax,(%esp)
801081d8:	e8 36 a9 ff ff       	call   80102b13 <kfree>
  for(i = 0; i < NPDENTRIES; i++){
801081dd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801081e1:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
801081e8:	76 b2                	jbe    8010819c <freevm+0x3c>
    }
  }
  kfree((char*)pgdir);
801081ea:	8b 45 08             	mov    0x8(%ebp),%eax
801081ed:	89 04 24             	mov    %eax,(%esp)
801081f0:	e8 1e a9 ff ff       	call   80102b13 <kfree>
}
801081f5:	c9                   	leave  
801081f6:	c3                   	ret    

801081f7 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801081f7:	55                   	push   %ebp
801081f8:	89 e5                	mov    %esp,%ebp
801081fa:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801081fd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108204:	00 
80108205:	8b 45 0c             	mov    0xc(%ebp),%eax
80108208:	89 44 24 04          	mov    %eax,0x4(%esp)
8010820c:	8b 45 08             	mov    0x8(%ebp),%eax
8010820f:	89 04 24             	mov    %eax,(%esp)
80108212:	e8 63 f8 ff ff       	call   80107a7a <walkpgdir>
80108217:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
8010821a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010821e:	75 0c                	jne    8010822c <clearpteu+0x35>
    panic("clearpteu");
80108220:	c7 04 24 78 8b 10 80 	movl   $0x80108b78,(%esp)
80108227:	e8 36 83 ff ff       	call   80100562 <panic>
  *pte &= ~PTE_U;
8010822c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010822f:	8b 00                	mov    (%eax),%eax
80108231:	83 e0 fb             	and    $0xfffffffb,%eax
80108234:	89 c2                	mov    %eax,%edx
80108236:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108239:	89 10                	mov    %edx,(%eax)
}
8010823b:	c9                   	leave  
8010823c:	c3                   	ret    

8010823d <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010823d:	55                   	push   %ebp
8010823e:	89 e5                	mov    %esp,%ebp
80108240:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80108243:	e8 66 f9 ff ff       	call   80107bae <setupkvm>
80108248:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010824b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010824f:	75 0a                	jne    8010825b <copyuvm+0x1e>
    return 0;
80108251:	b8 00 00 00 00       	mov    $0x0,%eax
80108256:	e9 03 01 00 00       	jmp    8010835e <copyuvm+0x121>
  for(i = 0; i < sz; i += PGSIZE){
8010825b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108262:	e9 d6 00 00 00       	jmp    8010833d <copyuvm+0x100>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108267:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010826a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108271:	00 
80108272:	89 44 24 04          	mov    %eax,0x4(%esp)
80108276:	8b 45 08             	mov    0x8(%ebp),%eax
80108279:	89 04 24             	mov    %eax,(%esp)
8010827c:	e8 f9 f7 ff ff       	call   80107a7a <walkpgdir>
80108281:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108284:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108288:	75 0c                	jne    80108296 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
8010828a:	c7 04 24 82 8b 10 80 	movl   $0x80108b82,(%esp)
80108291:	e8 cc 82 ff ff       	call   80100562 <panic>
    if(!(*pte & PTE_P))
80108296:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108299:	8b 00                	mov    (%eax),%eax
8010829b:	83 e0 01             	and    $0x1,%eax
8010829e:	85 c0                	test   %eax,%eax
801082a0:	75 0c                	jne    801082ae <copyuvm+0x71>
      panic("copyuvm: page not present");
801082a2:	c7 04 24 9c 8b 10 80 	movl   $0x80108b9c,(%esp)
801082a9:	e8 b4 82 ff ff       	call   80100562 <panic>
    pa = PTE_ADDR(*pte);
801082ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
801082b1:	8b 00                	mov    (%eax),%eax
801082b3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801082b8:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
801082bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801082be:	8b 00                	mov    (%eax),%eax
801082c0:	25 ff 0f 00 00       	and    $0xfff,%eax
801082c5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
801082c8:	e8 dc a8 ff ff       	call   80102ba9 <kalloc>
801082cd:	89 45 e0             	mov    %eax,-0x20(%ebp)
801082d0:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801082d4:	75 02                	jne    801082d8 <copyuvm+0x9b>
      goto bad;
801082d6:	eb 76                	jmp    8010834e <copyuvm+0x111>
    memmove(mem, (char*)P2V(pa), PGSIZE);
801082d8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801082db:	05 00 00 00 80       	add    $0x80000000,%eax
801082e0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801082e7:	00 
801082e8:	89 44 24 04          	mov    %eax,0x4(%esp)
801082ec:	8b 45 e0             	mov    -0x20(%ebp),%eax
801082ef:	89 04 24             	mov    %eax,(%esp)
801082f2:	e8 2a d0 ff ff       	call   80105321 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
801082f7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801082fa:	8b 45 e0             	mov    -0x20(%ebp),%eax
801082fd:	8d 88 00 00 00 80    	lea    -0x80000000(%eax),%ecx
80108303:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108306:	89 54 24 10          	mov    %edx,0x10(%esp)
8010830a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010830e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108315:	00 
80108316:	89 44 24 04          	mov    %eax,0x4(%esp)
8010831a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010831d:	89 04 24             	mov    %eax,(%esp)
80108320:	e8 f1 f7 ff ff       	call   80107b16 <mappages>
80108325:	85 c0                	test   %eax,%eax
80108327:	79 0d                	jns    80108336 <copyuvm+0xf9>
      kfree(mem);
80108329:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010832c:	89 04 24             	mov    %eax,(%esp)
8010832f:	e8 df a7 ff ff       	call   80102b13 <kfree>
      goto bad;
80108334:	eb 18                	jmp    8010834e <copyuvm+0x111>
  for(i = 0; i < sz; i += PGSIZE){
80108336:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010833d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108340:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108343:	0f 82 1e ff ff ff    	jb     80108267 <copyuvm+0x2a>
    }
  }
  return d;
80108349:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010834c:	eb 10                	jmp    8010835e <copyuvm+0x121>

bad:
  freevm(d);
8010834e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108351:	89 04 24             	mov    %eax,(%esp)
80108354:	e8 07 fe ff ff       	call   80108160 <freevm>
  return 0;
80108359:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010835e:	c9                   	leave  
8010835f:	c3                   	ret    

80108360 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108360:	55                   	push   %ebp
80108361:	89 e5                	mov    %esp,%ebp
80108363:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108366:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010836d:	00 
8010836e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108371:	89 44 24 04          	mov    %eax,0x4(%esp)
80108375:	8b 45 08             	mov    0x8(%ebp),%eax
80108378:	89 04 24             	mov    %eax,(%esp)
8010837b:	e8 fa f6 ff ff       	call   80107a7a <walkpgdir>
80108380:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80108383:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108386:	8b 00                	mov    (%eax),%eax
80108388:	83 e0 01             	and    $0x1,%eax
8010838b:	85 c0                	test   %eax,%eax
8010838d:	75 07                	jne    80108396 <uva2ka+0x36>
    return 0;
8010838f:	b8 00 00 00 00       	mov    $0x0,%eax
80108394:	eb 22                	jmp    801083b8 <uva2ka+0x58>
  if((*pte & PTE_U) == 0)
80108396:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108399:	8b 00                	mov    (%eax),%eax
8010839b:	83 e0 04             	and    $0x4,%eax
8010839e:	85 c0                	test   %eax,%eax
801083a0:	75 07                	jne    801083a9 <uva2ka+0x49>
    return 0;
801083a2:	b8 00 00 00 00       	mov    $0x0,%eax
801083a7:	eb 0f                	jmp    801083b8 <uva2ka+0x58>
  return (char*)P2V(PTE_ADDR(*pte));
801083a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083ac:	8b 00                	mov    (%eax),%eax
801083ae:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801083b3:	05 00 00 00 80       	add    $0x80000000,%eax
}
801083b8:	c9                   	leave  
801083b9:	c3                   	ret    

801083ba <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801083ba:	55                   	push   %ebp
801083bb:	89 e5                	mov    %esp,%ebp
801083bd:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
801083c0:	8b 45 10             	mov    0x10(%ebp),%eax
801083c3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
801083c6:	e9 87 00 00 00       	jmp    80108452 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
801083cb:	8b 45 0c             	mov    0xc(%ebp),%eax
801083ce:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801083d3:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
801083d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801083d9:	89 44 24 04          	mov    %eax,0x4(%esp)
801083dd:	8b 45 08             	mov    0x8(%ebp),%eax
801083e0:	89 04 24             	mov    %eax,(%esp)
801083e3:	e8 78 ff ff ff       	call   80108360 <uva2ka>
801083e8:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
801083eb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801083ef:	75 07                	jne    801083f8 <copyout+0x3e>
      return -1;
801083f1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801083f6:	eb 69                	jmp    80108461 <copyout+0xa7>
    n = PGSIZE - (va - va0);
801083f8:	8b 45 0c             	mov    0xc(%ebp),%eax
801083fb:	8b 55 ec             	mov    -0x14(%ebp),%edx
801083fe:	29 c2                	sub    %eax,%edx
80108400:	89 d0                	mov    %edx,%eax
80108402:	05 00 10 00 00       	add    $0x1000,%eax
80108407:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
8010840a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010840d:	3b 45 14             	cmp    0x14(%ebp),%eax
80108410:	76 06                	jbe    80108418 <copyout+0x5e>
      n = len;
80108412:	8b 45 14             	mov    0x14(%ebp),%eax
80108415:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80108418:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010841b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010841e:	29 c2                	sub    %eax,%edx
80108420:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108423:	01 c2                	add    %eax,%edx
80108425:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108428:	89 44 24 08          	mov    %eax,0x8(%esp)
8010842c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010842f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108433:	89 14 24             	mov    %edx,(%esp)
80108436:	e8 e6 ce ff ff       	call   80105321 <memmove>
    len -= n;
8010843b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010843e:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108441:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108444:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80108447:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010844a:	05 00 10 00 00       	add    $0x1000,%eax
8010844f:	89 45 0c             	mov    %eax,0xc(%ebp)
  while(len > 0){
80108452:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80108456:	0f 85 6f ff ff ff    	jne    801083cb <copyout+0x11>
  }
  return 0;
8010845c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108461:	c9                   	leave  
80108462:	c3                   	ret    
