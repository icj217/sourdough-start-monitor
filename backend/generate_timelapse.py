import boto3
from botocore.exceptions import ClientError
import os
import io
from PIL import Image, ImageSequence

s3_bucket = os.environ['S3_BUCKET_NAME']
timelapse_file = os.environ['TIMELAPSE_IMAGE']
timelapse_max_frames = int(os.environ['TIMELAPSE_MAX_FRAMES'])

s3 = boto3.client('s3')

def get_timelapse_file():
    try:
        return s3.get_object(Bucket=s3_bucket, Key=timelapse_file)
    except s3.exceptions.NoSuchKey:
        pass

def list_raw_files():
    files = s3.list_objects_v2(Bucket=s3_bucket, Prefix='raw/')
    return [file['Key'] for file in files['Contents']]

def get_raw_image(key):
    file = s3.get_object(Bucket=s3_bucket, Key=key)
    file_bytes = file['Body'].read()
    image = Image.open(io.BytesIO(file_bytes))
    image = image.resize((image.width // 2, image.height // 2))
    return image

def upload_timelapse(content):
    s3.put_object(Bucket=s3_bucket, Key=timelapse_file, Body=content, ContentType='image/gif', ACL='public-read')

def update_timelapse(current_timelapse, new_frame_key):
    new_timelapse = io.BytesIO()

    # Get old timelapse and new frame
    timelapse_bytes = current_timelapse['Body'].read()
    new_frame_image = get_raw_image(new_frame_key)
    timelapse_image = Image.open(io.BytesIO(timelapse_bytes))

    # Build new timelapse
    new_timelapse_frames = []
    frames_in_current_timelapse = ImageSequence.all_frames(timelapse_image)
    # Add current timelapse frames into new list
    if len(frames_in_current_timelapse) >= timelapse_max_frames:
        print('Reached maximum # of frames. Not including oldest frame in new GIF')
        new_timelapse_frames = frames_in_current_timelapse[1:]
    else:
        print('Adding all frames from current timelapse into new GIF')
        new_timelapse_frames = frames_in_current_timelapse
    print('Retained {} frames from current timelapse'.format(len(new_timelapse_frames)))
    new_timelapse_frames.append(new_frame_image)
    print('Total frames in new timelapse: {}'.format(len(new_timelapse_frames)))
    new_timelapse_frames[0].save(new_timelapse,
        format='gif',
        save_all=True,
        append_images=new_timelapse_frames[1:],
        duration=50,
        loop=0)
    return new_timelapse

def handler(event, context):
    # Get timelapse file from S3 (if exists)
    timelapse_obj = get_timelapse_file()
    # If exists and has content
    if timelapse_obj and timelapse_obj['ContentLength'] > 0:
        # modify existing GIF to remove top frame and add new frame to end
        print('Timelapse image found. Updating with new frame...')
        new_frame_key = event['Records'][0]['s3']['object']['key']
        new_timelapse = update_timelapse(timelapse_obj, new_frame_key)
        print('updated GIF: {} bytes'.format(len(new_timelapse.getvalue())))
        upload_timelapse(new_timelapse.getvalue())
    else:
        # generate from all files in the raw directory
        frames = []
        print('no timelapse image found')
        keys = list_raw_files()
        for key in keys:
            print('Retrieving {}'.format(key))
            image = get_raw_image(key)
            frames.append(image)
        timelapse = io.BytesIO()
        frames[0].save(timelapse,
            format='gif',
            save_all=True,
            append_images=frames[1:],
            duration=50,
            loop=0)
        print('saved GIF: {} bytes'.format(len(timelapse.getvalue())))
        upload_timelapse(timelapse.getvalue())
    return 'Done!'