
import sys
import os
import random
import cv2
import numpy as np
import math
import time
import kaldi_io


IMG_PATH = os.environ['IMG_PATH']

def display_image(image,name):
    cv2.imshow(name, image)
    key = cv2.waitKey(0)
    if key==27:
        sys.exit()

def normalize_gray_levels(image_gray):
    q5 = np.percentile(image_gray, 5)
    q30 = np.percentile(image_gray, 30)
    img_norm0 = image_gray.astype('float32')
    img_norm0 *=255./(q30-q5)
    img_norm0 -=255.*q5/(q30-q5)
    img_norm1 =  np.clip(img_norm0, 0, 255)
    return img_norm1.astype('uint8')


def get_mass_center(M,xshift=0):
    
    if M['m00']==0: 
        return None
    gravity_center_x = int(M['m10']/M['m00'])+xshift
    gravity_center_y = int(M['m01']/M['m00'])    
    return gravity_center_x,gravity_center_y

def sliding_window_number(image, stepSize, windowSize):
    return len(xrange(0, image.shape[1], stepSize))

def sliding_window(image, stepSize, windowSize):
    # slide a window across the image
    # generic version (sliding in x and y), but degenerated to sliding in x only
    #for y in xrange(0, image.shape[0], stepSize):
    y = 0
    for x in xrange(0, image.shape[1], stepSize):
        # yield the current window
        yield (x, y, image[y:y + windowSize[1], x:x + windowSize[0]])

def center_on_mass(img_inv, normalized_height=100):
    orig_height,orig_width = img_inv.shape

    # compute moments and mass center
    M = cv2.moments(img_inv,False)
    gx,gy = get_mass_center(M)

    # transform the image to put the mass center at the center of the image
    # crop or add white as needed
    if 2*gy == orig_height:
        # do nothing
        img_normalized = img_inv
    elif 2*gy < orig_height:
        # writing is at the top, cut the bottom part
        img_normalized = img_inv[0:2*gy,:]
    else :
        # add background at the bottom
        tmp_image = np.zeros((2*gy, orig_width, 3), np.uint8)
        img_normalized = cv2.cvtColor(tmp_image,cv2.COLOR_RGB2GRAY)

        img_normalized[0:orig_height,0:orig_width] = img_inv
    
    return img_normalized

def extract_features(images, ark_file,annotation,display=True):
    target_height = 72
    window_width =  3
    window_height = target_height
    window_shift = 3
    background_value = [0,0,0]
    display =  False

    number_of_chars = 0
    number_of_frames = 0
    with open(ark_file,'w') as f:
        for img_name,annot in zip(images,annotation):
            #print len(annot),annot
            number_of_chars += len(annot)
            # load image
            img_gray1 = cv2.imread(os.path.join(IMG_PATH,img_name),cv2.IMREAD_GRAYSCALE)

            height,width = img_gray1.shape
            #img_normalized = normalize_gray_levels(img_gray1)
            img_inv = cv2.bitwise_not(img_gray1)
            img_centered = center_on_mass(img_inv)
            
            # add white pixel at the begining and at the end        
            img_padded   =cv2.copyMakeBorder(img_centered, top=0, bottom=0, left=20, right=20, borderType= cv2.BORDER_CONSTANT, value=background_value )
            #display_image(img_padded,"padded")

            #resize to XX px heigth
            nb_lines,nb_cols = img_padded.shape
            resize_cols = int(math.floor(nb_cols*float(target_height)/nb_lines))
            img_norm_height = cv2.resize(img_padded,(resize_cols, target_height), interpolation = cv2.INTER_CUBIC)
            if display:
                display_image(img_norm_height,'features')
            
            # reserve memory for features
            nb_windows = sliding_window_number(img_norm_height, stepSize=window_shift, windowSize=(window_width, window_height))

            number_of_frames +=nb_windows
            feature_mat = np.zeros((target_height,nb_windows),dtype=int)
            if display:
                print "expect",nb_windows,"windows"
            for i,(x, y, window) in enumerate(sliding_window(img_norm_height, stepSize=window_shift, windowSize=(window_width, window_height))):
                    # if the window does not meet our desired window size, ignore it
                    if window.shape[0] != window_height or window.shape[1] != window_width:
                        continue
                    img_win = img_norm_height[y:y+window_height,x:x+window_width]
                    features = cv2.resize(img_win,(1,target_height),interpolation=cv2.INTER_AREA)
                    feature_mat[:,i] = np.reshape(features,(target_height,))
                    if display:
                        clone = img_norm_height.copy()
                        cv2.rectangle(clone, (x, y), (x + window_width, y + window_height), (255, 255, 255), 1)
                        cv2.imshow("sliding", clone)
                        cv2.waitKey(1)
                        time.sleep(0.02)
            #print feature_mat.shape
            feature_mat = np.transpose(feature_mat.astype('float32'))
            feature_mat *=1./255

            image_id = img_name.split('/')[2].replace('.tiff','')
            #print image_id
            #print number_of_frames,"frames",number_of_chars,"chars:", number_of_frames/number_of_chars,"frames/char"
            # write pixel values as features in file
            kaldi_io.write_mat(f, feature_mat, key=image_id)
        print number_of_frames/number_of_chars,"frames/char"
            

# read image list
images = []
annotations = []
input_file = sys.argv[1]
output_file = sys.argv[2]

for l in open(input_file).readlines():
    ltab= l.split()
    images.append(ltab[0])
    annotations.append(ltab[1])
print "processing",len(images),"files from",input_file," saved in",output_file
extract_features(images,output_file, annotations)


