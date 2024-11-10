from pprint import pprint
from PIL import Image
import piexif

codec = 'ISO-8859-1'  # or latin-1

def get_image_coordinates(filename):
    im = Image.open(filename)
    try:
        exif_dict = piexif.load(im.info.get('exif'))
        exif_tag_dict = {}
        thumbnail = exif_dict.pop('thumbnail')
        exif_tag_dict['thumbnail'] = thumbnail.decode(codec)

    
        for ifd in exif_dict:
            exif_tag_dict[ifd] = {}
            for tag in exif_dict[ifd]:
                try:
                    element = exif_dict[ifd][tag].decode(codec)

                except AttributeError:
                    element = exif_dict[ifd][tag]

                exif_tag_dict[ifd][piexif.TAGS[ifd][tag]["name"]] = element

    
        return [str(exif_tag_dict['GPS']['GPSLatitude'][2][0]/10000),str(exif_tag_dict['GPS']['GPSLongitude'][2][0]/10000)]
    except:
        return ["",""]

print(get_image_coordinates('TestingImages/WhatsApp Image 2024-04-14 at 10.55.22 PM.jpg'))
print(get_image_coordinates('TestingImages/DJI_0149.JPG'))
# print(image_coordinates('TestingImages/WhatsApp Image 2024-04-14 at 10.55.22 PM.jpg'))
