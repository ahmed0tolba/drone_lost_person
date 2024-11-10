import keras
import cv2
import keras.utils as image
import numpy as np
# import matplotlib.pyplot as plt
import sqlite3
from ultralytics import YOLO
from sklearn.cluster import KMeans
import matplotlib.pyplot as plt
import matplotlib.patches as patches

def predict_child_folder_by_face(img_name):
    # conn = sqlite3.connect("_database.db",uri=True)
    # cur = conn.cursor()
    # cur.execute('SELECT save_name FROM ' + 'model' + ' where id = (SELECT MAX(id) FROM model) ')
    # records = cur.fetchall()
    # save_name = records[0][0]
    # conn.commit()
    # cur.close()
    # conn.close() 

    import pickle
    with open("result_map.pkl",'rb') as fileWriteStream:
        result_map = pickle.load(fileWriteStream)

    model_cnn = keras.models.load_model("model.keras")

    face_classifier = cv2.CascadeClassifier(  # faces
        cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
    )
    # img = image.load_img(img_name,target_size=(64, 64))
    confs = []
    folders = []
    rois = []
    image_with_marked_rois = []
    img = cv2.imread(img_name)

    faces = face_classifier.detectMultiScale(
        img, scaleFactor=1.1, minNeighbors=5, minSize=(40, 40)
    )
    print("found ", len(faces) ," faces")
    for index,(x,y,w,h) in enumerate(faces):
        # cv2.rectangle(roi, (x, y), (x+w, y+h), (255, 255, 0), 4)
        roi_face = img[y:y+h,x:x+w]
        roi_face = cv2.cvtColor(roi_face, cv2.COLOR_BGR2RGB)
        roi_face = cv2.resize(roi_face, (64, 64),interpolation = cv2.INTER_LINEAR)
        roi_face = image.img_to_array(roi_face)
        roi_face = np.expand_dims(roi_face,axis =0) # tensor
        
        results = model_cnn.predict(roi_face)  

        tmp_img = img.copy()
        cv2.rectangle(tmp_img, (x, y), (x+w, y+h), (255, 255, 0), 4)

        confs.append(results.max()) # [ 99%, 88%,....]
        folders.append(result_map[np.argmax(results)]) # [3 , 4 ,....]
        rois.append(img[y:y+h,x:x+w]) # [ croped imaged 1 ,cropped image 2 , ...... ]
        image_with_marked_rois.append(tmp_img) # [ marked imaged 1 ,marked image 2 , ...... ]
        print("results:\n",np.float32(results))
        print("results max: ",results.max())
        print("best_folder: ",result_map[np.argmax(results)])

        # plt.figure(figsize=(10,5))
        # plt.imshow(img[y:y+h,x:x+w])
        # plt.show()
    # if len(faces) > 0:
    #     cv2.rectangle(image_with_marked_roi, (x, y), (x+w, y+h), (255, 255, 0), 4)
    # print("Child folder: ",result_map[np.argmax(results)])
    return folders,confs,rois,image_with_marked_rois

def hex2dec(hex):
    
    table = {'0': 0, '1': 1, '2': 2, '3': 3,  
            '4': 4, '5': 5, '6': 6, '7': 7, 
            '8': 8, '9': 9, 'A': 10, 'B': 11,  
            'C': 12, 'D': 13, 'E': 14, 'F': 15} 
    
    hexadecimal = hex.strip().upper() 
    dec = 0
    
    # computing max power value 
    size = len(hexadecimal) - 1
    
    for num in hexadecimal: 
        dec = dec + table[num]*16**size 
        size = size - 1
    
    return dec

def is_shirt_color_in_pic(img_name,color_r_required=0,color_g_required=0,color_b_required=0):
    tolerance = 50 # color degree
    table = {'0': 0, '1': 1, '2': 2, '3': 3,  
         '4': 4, '5': 5, '6': 6, '7': 7, 
         '8': 8, '9': 9, 'A': 10, 'B': 11,  
         'C': 12, 'D': 13, 'E': 14, 'F': 15} 
    
    model = YOLO("yolov8n.pt")
    img = cv2.imread(img_name)
    people = model(img)

    face_classifier = cv2.CascadeClassifier(  # faces
        cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
    )

    for child in people[0].boxes.xyxy:
        # cv2.rectangle(img, (int(child[0]), int(child[1])), (int(child[2]), int(child[3])), (255, 255, 0), 4)
        # print(int(child[0]),int(child[1]),int(child[2]),int(child[3]))
        child_roi = img[int(child[1]):int(child[3]),int(child[0]):int(child[2])] # region of interest
        # print("child",child)
        faces = face_classifier.detectMultiScale(
            child_roi, scaleFactor=1.1, minNeighbors=5, minSize=(40, 40)
        )
        
        height, width, dim = child_roi.shape
        # print("child_roi dim", height, width)
        if len(faces)>0:
            print("face",faces[0])
            roi = child_roi[faces[0][1]+faces[0][3]:faces[0][1]+faces[0][3]+ int(height/2)  , int(width/4):int(3*width/4), :]
        else:
            roi = child_roi[int(height/5):int(height/2), int(width/4):int(3*width/4), :]
        height, width, dim = roi.shape

        img_vec = np.reshape(roi, [height * width, dim] )

        kmeans = KMeans(n_clusters=3)
        kmeans.fit( img_vec )
        # plt.figure(figsize=(10,5))
        # plt.imshow(roi)
        # plt.show()
        unique_l, counts_l = np.unique(kmeans.labels_, return_counts=True)
        sort_ix = np.argsort(counts_l)
        sort_ix = sort_ix[::-1]

        # fig = plt.figure()
        # ax = fig.add_subplot(211)
        # x_from = 0.05

        for index,cluster_center in enumerate(kmeans.cluster_centers_[sort_ix]):
            if index == 0:
                facecolor='#%02x%02x%02x' % (int(cluster_center[2]), int(cluster_center[1]), int(cluster_center[0]) )
                # color_r_found = hex2dec(int(cluster_center[2]));color_g_found= hex2dec(int(cluster_center[1]));color_b_found = hex2dec(int(cluster_center[0]))
                # print(facecolor)
                # print("color_r_required", color_r_required,color_g_required,color_b_required)
                # print("cluster_center", cluster_center[2],cluster_center[1],cluster_center[0])
                if abs(cluster_center[2] - color_r_required) < tolerance and abs(cluster_center[1] - color_g_required) < tolerance and abs(cluster_center[0] - color_b_required) < tolerance :
                    return True
                # ax.add_patch(patches.Rectangle( (x_from, 0.05), 0.29, 0.9, alpha=None,facecolor=facecolor) )
                # x_from = x_from + 0.31
                # ax = fig.add_subplot(212)
                # plt.imshow(img[int(child[1]):int(child[3]),int(child[0]):int(child[2])])
            else:
                break
        
        # plt.show()

    return False

# predict_child_folder_by_color("TestingImages/WhatsApp Image 2024-04-14 at 10.55.22 PM.jpg")
# predict_child_folder_by_color("TestingImages/2.jpg")
# predict_child_folder("images/Training Images/1/WhatsApp Image 2024-01-18 at 10.09.39 PM (7).jpeg_face1.jpg")
# predict_child_folder("images/Training Images/1/WhatsApp Image 2024-01-18 at 10.09.39 PM (8).jpeg_face1.jpg")
# predict_child_folder("images/Training Images/1/WhatsApp Image 2024-01-18 at 10.09.39 PM (9).jpeg_face1.jpg")
# predict_child_folder("images/Training Images/1/WhatsApp Image 2024-01-18 at 10.09.43 PM (1).jpeg_face1.jpg")
# predict_child_folder("images/Training Images/1/WhatsApp Image 2024-01-18 at 10.09.43 PM (2).jpeg_face1.jpg")
# predict_child_folder("images/Training Images/1/WhatsApp Image 2024-01-18 at 10.09.43 PM (3).jpeg_face1.jpg")
# predict_child_folder("images/Training Images/1/WhatsApp Image 2024-01-18 at 10.09.43 PM (4).jpeg_face1.jpg")
# predict_child_folder("images/Training Images/1/WhatsApp Image 2024-01-18 at 10.09.43 PM (5).jpeg_face1.jpg")
# predict_child_folder("images/Testing Images/3/Unknown-19.jpeg_face1.jpg")

# predict_child_folder("TestingImages/WhatsApp Image 2024-04-14 at 10.55.20 PM.jpg")
