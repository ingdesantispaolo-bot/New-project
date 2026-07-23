param(
    [Parameter(Mandatory = $true)]
    [string[]] $Path
)

$ErrorActionPreference = "Stop"

# Fallback riproducibile per asset generati con una scacchiera rasterizzata:
# rimuove soltanto la grande componente chiara/neutra connessa ai bordi.
# Le parti chiare interne all'oggetto restano intatte perché isolate dal contorno.

Add-Type -AssemblyName System.Drawing

if (-not ("CheckerboardAlpha" -as [type])) {
    Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class CheckerboardAlpha
{
    public static void Convert(string sourcePath)
    {
        string temporary = sourcePath + ".alpha.png";
        using (var source = new Bitmap(sourcePath))
        using (var bitmap = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb))
        {
            using (var graphics = Graphics.FromImage(bitmap))
            {
                graphics.CompositingMode = System.Drawing.Drawing2D.CompositingMode.SourceCopy;
                graphics.DrawImageUnscaled(source, 0, 0);
            }

            var rect = new Rectangle(0, 0, bitmap.Width, bitmap.Height);
            var data = bitmap.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int stride = Math.Abs(data.Stride);
            byte[] pixels = new byte[stride * bitmap.Height];
            Marshal.Copy(data.Scan0, pixels, 0, pixels.Length);

            int count = bitmap.Width * bitmap.Height;
            var visited = new bool[count];
            var queue = new int[count];
            int head = 0;
            int tail = 0;

            Action<int, int> enqueue = (x, y) => {
                int id = y * bitmap.Width + x;
                if (visited[id] || !IsBackground(pixels, stride, x, y))
                    return;
                visited[id] = true;
                queue[tail++] = id;
            };

            for (int x = 0; x < bitmap.Width; x++)
            {
                enqueue(x, 0);
                enqueue(x, bitmap.Height - 1);
            }
            for (int y = 1; y < bitmap.Height - 1; y++)
            {
                enqueue(0, y);
                enqueue(bitmap.Width - 1, y);
            }

            while (head < tail)
            {
                int id = queue[head++];
                int x = id % bitmap.Width;
                int y = id / bitmap.Width;
                if (x > 0) enqueue(x - 1, y);
                if (x + 1 < bitmap.Width) enqueue(x + 1, y);
                if (y > 0) enqueue(x, y - 1);
                if (y + 1 < bitmap.Height) enqueue(x, y + 1);
            }

            for (int id = 0; id < count; id++)
            {
                if (!visited[id])
                    continue;
                int x = id % bitmap.Width;
                int y = id / bitmap.Width;
                pixels[y * stride + x * 4 + 3] = 0;
            }

            Marshal.Copy(pixels, 0, data.Scan0, pixels.Length);
            bitmap.UnlockBits(data);

            bitmap.Save(temporary, ImageFormat.Png);
        }
        File.Copy(temporary, sourcePath, true);
        File.Delete(temporary);
    }

    private static bool IsBackground(byte[] pixels, int stride, int x, int y)
    {
        int offset = y * stride + x * 4;
        int blue = pixels[offset];
        int green = pixels[offset + 1];
        int red = pixels[offset + 2];
        int minimum = Math.Min(red, Math.Min(green, blue));
        int maximum = Math.Max(red, Math.Max(green, blue));
        return minimum >= 224 && maximum - minimum <= 12;
    }
}
'@
}

foreach ($item in $Path) {
    $resolved = (Resolve-Path -LiteralPath $item).Path
    [CheckerboardAlpha]::Convert($resolved)
    Write-Output "Alpha ricostruito: $resolved"
}
