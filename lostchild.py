from flask import Flask, request, jsonify, redirect, url_for,make_response  # pip install asasdasd
import sqlite3 # pip install sqlite3
import os
from werkzeug.utils import secure_filename
import base64
import datetime
from datetime import datetime, timedelta
from trainmodel import trainmodel
from find_child import predict_child_folder_by_face ,is_shirt_color_in_pic
import cv2 
from threading import Thread
import shutil
from pprint import pprint
from PIL import Image
import piexif
from flask import send_from_directory

app = Flask(__name__)
database_name = "_database.db"
users_table_name = "users"
report_table_name = "reports"
model_table_name = "model"
# basedir = os.path.abspath(os.path.dirname(__file__))
# UPLOAD_FOLDER = 'images'
global model_is_being_trained 
model_is_being_trained = False
drone_search_images_directory = "TestingImages/"
drone_results_images_directory = "results_images/"
training_images_directory = "images/"

conn = sqlite3.connect(database_name,uri=True)
conn.execute('CREATE TABLE IF NOT EXISTS ' + users_table_name + '(id INTEGER PRIMARY KEY AUTOINCREMENT,email TEXT UNIQUE NOT NULL,password TEXT NOT NULL,admin boolean default False , name TEXT ,reportscount INTEGER default 0,openreportscount INTEGER default 0, hasunfinishedreport BOOLEAN default False)')
conn.execute('CREATE TABLE IF NOT EXISTS ' + report_table_name + '(id INTEGER PRIMARY KEY AUTOINCREMENT,email TEXT NOT NULL,name TEXT NOT NULL,reportname TEXT NOT NULL,status TEXT default "pending",submitdate TEXT default "",acceptdate TEXT default "",finishdate TEXT default "", rejected BOOLEAN default False ,conf REAL default 0, bestimage TEXT default "", bestimageroimarked TEXT default "", bestimageroi TEXT default "", report_lat TEXT default "", report_lng TEXT default "", result_lat TEXT default "", result_lng TEXT default "" , color_r INTEGER default 0, color_g INTEGER default 0, color_b INTEGER default 0 , same_color_images TEXT default "")')
# conn.execute('CREATE TABLE IF NOT EXISTS ' + model_table_name + '(id INTEGER PRIMARY KEY AUTOINCREMENT,save_name TEXT NOT NULL)')

cur = conn.cursor()
cur.execute('select * from '+ users_table_name )
records = cur.fetchall()
if len(records)==0:
    sqlite_insert_query = 'INSERT INTO '+ users_table_name +' (email,password,admin) VALUES (?,?,?);'
    data_tuple = ("qwe","qwe","True",)
    cur.execute(sqlite_insert_query,data_tuple)
    conn.commit()
cur.close()
conn.close()   

@app.route('/status', methods=['GET'])   # endpoint
def home():
    return "Server is running"

def train_and_search():
    skip_training = True  # do not train
    # skip_training = False # train
    if not skip_training:
        global model_is_being_trained
        if not model_is_being_trained:
            model_is_being_trained = True
            trainmodel()
            model_is_being_trained = False

    # clearing previous images found by color
    conn = sqlite3.connect(database_name,uri=True)
    curr = conn.cursor()     
    curr.execute('UPDATE ' + report_table_name + ' SET same_color_images = ? ', ("",))
    conn.commit() 

    for filename in os.listdir(drone_search_images_directory):       
        print ("\n ----- checking image : ", filename)
        folders,confs,rois,image_with_marked_rois = predict_child_folder_by_face(drone_search_images_directory+filename)
        # [ 1 2 asdahmed... asdnoha...] 
        print(folders,confs)
        for index,conf in enumerate(confs):
            curr.execute('SELECT conf,reportname FROM ' + report_table_name + ' where reportname = ? ' , (folders[index],))
            records = curr.fetchall()
            if len(records) > 0:
                conf_old = records[0][0]
                reportname = records[0][1]
                print(conf_old)
                if confs[index] > conf_old:
                    bestimageroi_filename = filename[:-4] + reportname + "roi" + filename[-4:] # img(.jpg) + asdahmedcolordate + roi + .jpg
                    bestimageroimarked_filename = filename[:-4] + reportname + "roimarked" + filename[-4:] # img(.jpg) + asdahmedcolordate + roimarked + .jpg
                    cv2.imwrite(drone_results_images_directory + bestimageroi_filename, rois[index]) 
                    cv2.imwrite(drone_results_images_directory + bestimageroimarked_filename, image_with_marked_rois[index]) 
                    result_lat , result_lng = get_image_coordinates(drone_search_images_directory+filename)
                    curr.execute('UPDATE ' + report_table_name + ' SET status = ? , conf = ? , bestimage = ? , finishdate = ? , result_lat = ? , result_lng = ? ,bestimageroimarked = ?, bestimageroi = ? WHERE reportname = ? ', ("found",int(confs[index]*100),filename,datetime.now() ,result_lat , result_lng,bestimageroimarked_filename,bestimageroi_filename,folders[index],))
                    conn.commit() 
        
        # searching with color for those who were not found
        curr.execute('SELECT reportname,color_r,color_g,color_b,same_color_images FROM ' + report_table_name + ' where conf = ? ' , (0,))
        records = curr.fetchall()
        images_with_same_shirt_color = ""
        if len(records):
            for record in records:
                reportname = record[0]
                color_r = record[1]
                color_g = record[2]
                color_b = record[3]
                # print(color_r,color_g,color_b)
                same_color_images = record[4]
                if is_shirt_color_in_pic(drone_search_images_directory+filename,color_r,color_g,color_b):
                    images_with_same_shirt_color = same_color_images + "," + filename 
                    result_lat , result_lng = get_image_coordinates(drone_search_images_directory+filename)
                    curr.execute('UPDATE ' + report_table_name + ' SET status = ? , same_color_images = ? , result_lat = ? , result_lng = ? WHERE reportname = ? ', ("found",images_with_same_shirt_color, result_lat , result_lng,reportname,))
                    conn.commit() 

    curr.close()
    conn.close()    

@app.route('/gettrainingstatus', methods=['POST'])
def gettrainingstatus():
    global model_is_being_trained
    message = ""
    reports_count = 0
    not_found_count = 0
    pending_count = 0
    found_count = 0
    conn = sqlite3.connect(database_name,uri=True)
    curr = conn.cursor()    
    curr.execute('SELECT * FROM ' + report_table_name )
    records = curr.fetchall()
    reports_count = len(records)
    curr.execute('SELECT * FROM ' + report_table_name + ' where status = ? ' , ("not found",))
    records = curr.fetchall()
    not_found_count = len(records)
    curr.execute('SELECT * FROM ' + report_table_name + ' where status = ? ' , ("pending",))
    records = curr.fetchall()
    pending_count = len(records)
    curr.execute('SELECT * FROM ' + report_table_name + ' where status = ? ' , ("found",))
    records = curr.fetchall()
    found_count = len(records)
    curr.close()
    conn.close()  
    message = "There are " +  str(reports_count) + " reports, " + str(pending_count) + " pending, " + str(found_count) + " found, and " + str(not_found_count) + " not found."
    if model_is_being_trained:
        message += "\n Model is currently being trained."

    resp = jsonify(model_is_being_trained = model_is_being_trained ,reports_count = reports_count, found_count = found_count , not_found_count = not_found_count , pending_count = pending_count , message = message)
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    return resp

@app.route('/acceptrequestsearch', methods=['POST'])
def acceptrequestsearch():
    global model_is_being_trained
    # report_name = request.args.get('report_name')
    # adminemail = request.args.get('email')
    already_training = False
    started_training = False
    message = ""
    if not model_is_being_trained:
        t = Thread(target=train_and_search,args=[])
        t.start()
        started_training = True
        message = "Started Traing and searcing successfully , results will be ready after 1 minute ISA."
        conn = sqlite3.connect(database_name,uri=True)
        curr = conn.cursor()    
        curr.execute('UPDATE ' + report_table_name + ' SET status = ? WHERE status = ? ', ("searching","pending",))
        conn.commit() 
        curr.close()
        conn.close()    
    else:
        already_training = True
        message = "Already Traing and searcing ... , results will be ready after 1 minute ISA."
    
    
    resp = jsonify(started_training = started_training , already_training = already_training , message = message)
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    return resp

@app.route('/deletereport', methods=['POST'])
def deletereport():
    reportname = request.args.get('report_name')
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('DELETE from ' + report_table_name + ' where reportname = ? ' , (reportname,))
    con.commit()

    cur.execute('SELECT bestimageroimarked , bestimageroi FROM ' + report_table_name + ' where reportname = ? ' , (reportname,))
    records = cur.fetchall()
    for record in records:
        os.remove(training_images_directory + record[0])
        os.remove(training_images_directory + record[1])
    cur.close()
    con.close()

    shutil.rmtree(training_images_directory + reportname)

    resp = jsonify(message = "")
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    return resp


@app.route('/getreport', methods=['POST'])
def getreport():
    reportname = request.args.get('reportname')

    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('SELECT * FROM ' + report_table_name + ' where reportname = ? ' , (reportname,))

    records = cur.fetchall()
    name = records[0][2]
    status = records[0][4]
    submitdate = records[0][5]
    acceptdate = records[0][6]
    finishdate = records[0][7]
    rejected = records[0][8]
    conf = records[0][9]
    # print(conf)
    bestimage = drone_search_images_directory + records[0][10]
    result_lat = records[0][15]
    result_lng = records[0][16]
    same_color_images = records[0][20].split(",")
    if len(same_color_images) > 0:
        same_color_images.pop(0)
    cur.close()
    con.close()

    resp = jsonify(name = name , status = status , submitdate = submitdate , acceptdate = acceptdate , finishdate = finishdate , rejected = rejected , conf = conf , bestimage = bestimage , result_lat = result_lat , result_lng = result_lng, same_color_images = same_color_images)
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    return resp



@app.route('/getreports', methods=['POST'])
def getreports():
    email = request.args.get('email')
    admin = request.args.get('admin')
    # print(email)
    # print(admin)
    name_list=[]
    reportname_list=[]
    status_list=[]
    submitdate_list = []
    acceptdate_list = []
    finishdate_list = []
    rejected_list = []
    
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    if admin == "true":
        cur.execute('SELECT * FROM ' + report_table_name )
    else:
        cur.execute('SELECT * FROM ' + report_table_name + ' where email = ? ' , (email,))

    records = cur.fetchall()
    for record in records:
        name_list.append(record[2])
        reportname_list.append(record[3])
        status_list.append(record[4])
        submitdate_list.append(record[5])
        acceptdate_list.append(record[6])
        finishdate_list.append(record[7])
        rejected_list.append(record[8])
    
    cur.close()
    con.close()

    resp = jsonify(name_list = name_list , status_list = status_list,reportname_list=reportname_list,submitdate_list=submitdate_list,acceptdate_list=acceptdate_list,finishdate_list=finishdate_list,rejected_list=rejected_list)
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    return resp

@app.route('/signin', methods=['POST'])
def signin():
    success = False
    admin = False
    message = "Wrong Email or Password."
    email = request.args.get('email')
    password = request.args.get('password')

    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('SELECT * FROM ' + users_table_name + ' where email = ? and password = ? ' , (email,password,))
    records = cur.fetchall()
    if len(records) > 0 :
        success = True
        message = ""
        if records[0][3] == "True":
            admin = True
    cur.close()
    con.close()

    resp = jsonify(success = success ,message = message ,admin = admin)
    resp.headers.add("Access-Control-Allow-Origin","*")
    return resp

@app.route('/signup', methods=['POST'])
def signup():
    success = True
    message = ""
    name = request.args.get('name')
    email = request.args.get('email')
    password = request.args.get('password')
    confirmpassword = request.args.get('confirmpassword')

    # Check if email already exists
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('SELECT * FROM ' + users_table_name + ' where email = ? ' , (email,))
    records = cur.fetchall()
    cur.close()
    con.close()

    if len(records) == 0 :
        # sign up used to DB
        con = sqlite3.connect(database_name,uri=True)
        cur = con.cursor()
        cur.execute('INSERT INTO ' + users_table_name + ' (email,password,name) VALUES (?,?,?) ' , (email,password,name))
        con.commit()
        cur.close()
        con.close()   
        message = " signed up successfully"     
    else:
        print("email already used")
        success = False
        message = "email already used"

    resp = jsonify(success = success ,message = message)
    resp.headers.add("Access-Control-Allow-Origin","*")
    return resp


@app.route('/submitimage', methods=['POST'])
def submitimage():
    success = True
    message = "Report Submitted Successfully"

    if request.method == 'POST':        
        name = request.args.get('name')
        email = request.args.get('email')
        color = request.args.get('color')
        # expected_images_count = request.args.get('expected_images_count')
        images_save_directory= request.args.get('images_save_directory')
        if images_save_directory == "":
            images_save_directory = secure_filename(email + name + color + str(datetime.now()))
        
        if not os.path.exists(training_images_directory + images_save_directory):    
            os.makedirs(training_images_directory + images_save_directory)

        images = os.listdir(training_images_directory + images_save_directory)        

        with open(training_images_directory + images_save_directory + "/" + str(len(images)) + ".jpg", "wb") as fh:
            fh.write(base64.decodebytes(request.data))
        
    
    # images = os.listdir(training_images_directory + images_save_directory) 
        
    # if len(images) == int(expected_images_count):
    #     print("train")

    resp = jsonify(images_save_directory = images_save_directory, success = success , message = message)
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    return resp

@app.route('/requestdirectory', methods=['POST'])
def requestdirectory():
    # if request.method == 'POST':        
    name = request.args.get('name')
    email = request.args.get('email')
    color = request.args.get('color')
    report_lat = request.args.get('report_lat')
    report_lng = request.args.get('report_lng')
    images_save_directory = secure_filename(email + name + color + str(datetime.now()))
    if color.lower() == "red":
        color_r = 255;color_g = 0;color_b = 0
    if color.lower() == "green":
        color_r = 0;color_g = 255;color_b = 0
    if color.lower() == "blue":
        color_r = 255;color_g = 0;color_b = 255
    if color.lower() == "white":
        color_r = 255;color_g = 255;color_b = 255    
    if color.lower() == "black":
        color_r = 0;color_g = 0;color_b = 0    
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('INSERT INTO ' + report_table_name + ' (email,name,reportname,submitdate,report_lat,report_lng,color_r,color_g,color_b) VALUES (?,?,?,?,?,?,?,?,?) ' , (email,name,images_save_directory,datetime.now(),report_lat,report_lng,color_r,color_g,color_b,))
    con.commit()
    cur.close()
    con.close()   

    resp = jsonify(images_save_directory = images_save_directory)
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    return resp

@app.route('/request_reports', methods=['POST'])
def request_reports():

    reports_names_list = []
    reports_status_list = []
    email = request.args.get('email')
    admin = request.args.get('admin')
    con = sqlite3.connect(database_name,uri=True)
    cur = con.cursor()
    cur.execute('SELECT * FROM ' + report_table_name + ' where email = ? ' , (email,))
    records = cur.fetchall()
    for row in records:
        reports_names_list.append(row["name"])
        reports_status_list.append(row["status"])
    cur.close()
    con.close()

    resp = jsonify(reports_names_list = reports_names_list,reports_status_list=reports_status_list)
    resp.status_code = 200
    resp.headers.add("Access-Control-Allow-Origin", "*") 
    return resp

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

@app.route('/TestingImages/<path:path>')
def send_report(path):
    return send_from_directory('TestingImages', path)

if __name__ == '__main__':
    app.run(debug=True,port=13000,use_reloader=False,host='0.0.0.0')

# flutter run -d chrome --web-browser-flag "--disable-web-security"