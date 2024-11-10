

import datetime
import sqlite3

def trainmodel(showplot = False):
    # reader class
    from keras.preprocessing.image import ImageDataGenerator
    train_gen = ImageDataGenerator(shear_range=0.1,zoom_range=.1,horizontal_flip=True)
    import os
    # os.remove("result_map.pkl")
    # images directory
    # train_folder = 'images/Training Images'
    train_folder = 'images/'
    # valid = 'images/Validation Images'
    valid = 'Validation Images/'

    # reading images
    train_data = train_gen.flow_from_directory(train_folder,target_size=(64,64),batch_size=32,class_mode='categorical')
    validation_data = train_gen.flow_from_directory(valid,target_size=(64,64),batch_size=32,class_mode='categorical')

    # copying class names
    train_classes = train_data.class_indices
    print(train_classes)

    # class names to a dictionary
    result_map = {}
    for faceValue,faceName in zip(train_classes.values(),train_classes.keys()):
        result_map[faceValue] = faceName


    from keras.models import Sequential
    from keras.layers import Convolution2D,MaxPool2D,Flatten,Dense
    model_cnn = Sequential()
    model_cnn.add(Convolution2D(32,kernel_size=(5,5),strides=(1,1),input_shape=(64,64,3),activation="relu"))
    model_cnn.add(MaxPool2D(pool_size=(2,2)))
    model_cnn.add(Convolution2D(64,kernel_size=(5,5),strides=(1,1),activation="relu"))
    model_cnn.add(MaxPool2D(pool_size=(2,2)))
    model_cnn.add(Convolution2D(128,kernel_size=(5,5),strides=(1,1),activation="relu"))
    model_cnn.add(MaxPool2D(pool_size=(2,2)))
    model_cnn.add(Flatten())
    model_cnn.add(Dense(len(result_map),activation='softmax')) # softmax sigmoid
    model_cnn.compile(loss="categorical_crossentropy",optimizer='adam',metrics=["accuracy"])

    # monitor for heighest accuracy
    from keras.callbacks import EarlyStopping
    earlystop= EarlyStopping(monitor='val_accuracy',mode="max",patience=50,restore_best_weights=True)

    import time
    start_time = time.time()
    # history = model_cnn.fit(train_data,steps_per_epoch=5,epochs=50,validation_data=validation_data,callbacks=[earlystop])
    history = model_cnn.fit(train_data,steps_per_epoch=5,epochs=50,validation_data=train_data,callbacks=[earlystop])
    end_time = time.time()

    import matplotlib.pyplot as plt

    print("Total training time= " , round((end_time-start_time)/60) ," minutes")

    # save_name = datetime.now()

    # conn = sqlite3.connect("_database.db",uri=True)
    # cur = conn.cursor()
    # cur.execute('INSERT INTO ' + "model" + ' (modelname) VALUES (?) ' , (save_name))
    # conn.commit()
    # cur.close()
    # conn.close() 

    # save model
    model_cnn.save("model.keras")

    # save dictionary 
    import pickle
    with open("result_map.pkl",'wb') as fileWriteStream:
        pickle.dump(result_map,fileWriteStream)
    # plt.figure(1)
    # # summarize history for accuracy
    # plt.subplot(211)
    # plt.plot(history.history['accuracy'])
    # plt.plot(history.history['val_accuracy'])
    # plt.title('Model Accuracy')
    # plt.ylabel('Accuracy')
    # plt.xlabel('Epoch')
    # plt.legend(['Training', 'Validation'], loc='lower right')

    # # summarize history for loss
    # plt.subplot(212)
    # plt.plot(history.history['loss'])
    # plt.plot(history.history['val_loss'])
    # plt.title('Model Loss')
    # plt.ylabel('Loss')
    # plt.xlabel('Epoch')
    # plt.legend(['Training', 'Validation'], loc='upper right')
    # if showplot:
    #     plt.show()

    # train_data = train_gen.flow_from_directory(train_folder,target_size=(64,64),batch_size=32,class_mode='categorical')
    # model_cnn.add(Convolution2D(32,kernel_size=(5,5),strides=(1,1),input_shape=(64,64,3),activation="relu"))
    # model_cnn.add(MaxPool2D(pool_size=(2,2)))
    # model_cnn.add(Convolution2D(32,kernel_size=(5,5),strides=(1,1),activation="relu"))
    # model_cnn.add(MaxPool2D(pool_size=(2,2)))
    # model_cnn.add(Flatten())
    # model_cnn.add(Dense(len(result_map)))
    # model_cnn.compile(loss="categorical_crossentropy",optimizer='adam',metrics=["accuracy"])
    # model_cnn.fit(train_data,steps_per_epoch=5,epochs=200,validation_data=train_data)
    # Epoch 198/200
    # 5/5 [==============================] - 4s 961ms/step - loss: 7.1524 - accuracy: 0.0875 - val_loss: 7.1335 - val_accuracy: 0.0700
    # Epoch 199/200
    # 5/5 [==============================] - 4s 880ms/step - loss: 6.8502 - accuracy: 0.0625 - val_loss: 7.1335 - val_accuracy: 0.0700
    # Epoch 200/200
    # 5/5 [==============================] - 4s 965ms/step - loss: 7.3539 - accuracy: 0.0562 - val_loss: 7.1335 - val_accuracy: 0.0700

    # train_data = train_gen.flow_from_directory(train_folder,target_size=(64,64),batch_size=32,class_mode='categorical')
    # model_cnn.add(Convolution2D(32,kernel_size=(5,5),strides=(1,1),input_shape=(64,64,3),activation="relu"))
    # model_cnn.add(MaxPool2D(pool_size=(2,2)))
    # model_cnn.add(Convolution2D(64,kernel_size=(5,5),strides=(1,1),activation="relu"))
    # model_cnn.add(MaxPool2D(pool_size=(2,2)))
    # model_cnn.add(Flatten())
    # model_cnn.add(Dense(len(result_map)))
    # model_cnn.compile(loss="categorical_crossentropy",optimizer='adam',metrics=["accuracy"])
    # history = model_cnn.fit(train_data,steps_per_epoch=5,epochs=200,validation_data=train_data)