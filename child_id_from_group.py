from ultralytics import YOLO
import cv2
import keras
import keras.utils as image
import numpy as np
import matplotlib.pyplot as plt

model = YOLO("yolov8n.pt") # childern

# img = cv2.imread("TestingImages/WhatsApp Image 2024-04-14 at 10.55.15 PM.jpg")
# img = cv2.imread("TestingImages/WhatsApp Image 2024-04-14 at 10.55.20 PM.jpg")
# img = cv2.imread("TestingImages/WhatsApp Image 2024-04-14 at 10.55.22 PM (2).jpg")
img = cv2.imread("TestingImages/WhatsApp Image 2024-04-14 at 10.55.22 PM (1).jpg")

people = model(img)

model_cnn = keras.models.load_model("model.keras")  # face of who -> 100  

face_classifier = cv2.CascadeClassifier(  # faces
    cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
)

import pickle
with open("result_map.pkl",'rb') as fileWriteStream:  # > 100   ??   -> ahmed
    result_map = pickle.load(fileWriteStream)

print(result_map)

for child in people[0].boxes.xyxy:
    # cv2.rectangle(img, (int(child[0]), int(child[1])), (int(child[2]), int(child[3])), (255, 255, 0), 4)
    # print(int(child[0]),int(child[1]),int(child[2]),int(child[3]))
    roi = img[int(child[1]):int(child[3]),int(child[0]):int(child[2])] # region of interest
    # plt.figure(figsize=(10,5))
    # plt.imshow(roi)
    # plt.show()

    faces = face_classifier.detectMultiScale(
        roi, scaleFactor=1.1, minNeighbors=5, minSize=(40, 40)
    )

    for (x,y,w,h) in faces:
        # cv2.rectangle(roi, (x, y), (x+w, y+h), (255, 255, 0), 4)
        roi_face = roi[y:y+h,x:x+w]

        # use our model for roi_face
        img_ = cv2.cvtColor(roi_face, cv2.COLOR_BGR2RGB)
        img_ = cv2.resize(img_,(64,64)) # cv image 
        img_ = image.img_to_array(img_)
        img_ = np.expand_dims(img_,axis =0) # tensor
        results = model_cnn.predict(img_)   #  0:.01 , 1:.9 , 2:.05 ...... 
        print(results)
        print("child folder:" , result_map[np.argmax(results)], " propapility : ",results.max())


        plt.figure(figsize=(10,5))
        plt.imshow(roi_face)
        plt.show()

# listen for requests /check_image (image)
# model (image)
# return child found , image
# flutter (login, search post ) <- -> python (username-pass , model ,sqlite ) , login , register  
