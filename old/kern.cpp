int x, y; /* Our global 'x' and 'y' */
char color; /* Our global color attribute */
void putc( unsigned char c )
{
  char *vidmem = (char*)0xB8000; /* pointer to video memory */
  int pos = ( y * 2 ) + x; /* Get the position */
  vidmem[pos]	= c; /* print the character */
  vidmem[pos++] = color; /* Set the color attribute */
  if (c == '\n') // newline
  {
    y++;
    x = 0;
  }
  else
    x += 2; // 2 bytes per char
}
void kern_main(){
  putc('s');
}