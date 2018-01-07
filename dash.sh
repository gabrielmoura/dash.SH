#!/bin/bash
# @author Gabriel Moura <g@srmoura.com.br>
# Este script tem como papel converter vídeos usando ffmpeg e funções do GPAC
echo -e "\033[0;31mÉ necessário que tenha MP4Box da GPAC e ffmpeg instalado.\033[0m";
#Sem parametro mensagem de ajuda
if [ -z "$1" ];then
echo -e "Abaixo esta os modos de uso disponiveis.\n";
echo "Converter WEBM: ./dash.sh -webm video.mp4";
echo "Converter ALL: ./dash.sh -all video.mp4 (converte a maioria)";
echo "Converter MKV: ./dash.sh -mkv video.mp4 (não codifica)";
echo "Converter MKV: ./dash.sh -mkv2 video.mp4 (codifica|lossless)";
echo -e "\nGerar DASH: ./dash.sh -make video.mp4";
echo "Gerar DASH 2: ./dash.sh -make2 video.mp4";
echo -e "\nPressione Ctrl+C a qualquer momento para cancelar.";
else

#Parametro -all
if [ "$1" = "-all" ];then
if [ -z "$2" ];then
echo -e "\033[0;31mÉ necessário passar o video.\033[0m";
else
ffmpeg -i $2 -f mp4 -vcodec libx264 -preset fast -profile:v main -acodec aac ./output.mp4 -hide_banner
fi
fi #Fim do parametro -all

#Parametro -mkv
#Converte o vídeo de mkv para mp4 mudando poucas coisas sem codificar-lo
if [ "$1" = "-mkv" ];then
if [ -z "$2" ];then
echo -e "\033[0;31mÉ necessário passar o video.\033[0m";
else
ffmpeg -i $2 -codec copy ./output.mp4
fi
fi #Fim do parametro -mkv

#Parametro -mkv2
#Converte o vídeo de mkv para mp4 o codificando.
if [ "$1" = "-mkv2" ];then
if [ -z "$2" ];then
echo -e "\033[0;31mÉ necessário passar o video.\033[0m";
else
ffmpeg -i $2 -c:v libx265 -preset veryslow -x265-params lossless=1 ./output.mp4
fi
fi #Fim do parametro -mkv2

#Parametro -webm
if [ "$1" = "-webm" ];then
if [ -z "$2" ];then
echo -e "\033[0;31mÉ necessário passar o video.\033[0m";
else
ffmpeg -fflags +genpts -i $2 -r 24 ./output.mp4
fi
fi #Fim do parametro -webm

#Parametro -make
if [ "$1" = "-make" ];then
if [ -z "$2" ];then
echo -e "\033[0;31mÉ necessário passar o video.\033[0m";
else
echo -e "\033[1;32mExtraindo audio do vídeo.\033[0m";
separated="_separated";
dash="_dash";
mkdir -p $separated
mkdir -p $dash
ffmpeg -i $2 -vn ./"$separated"/audio.aac
echo -e "\033[1;32mAudio extraido.\033[0m";

#Usando veryslow por conseguir produzir um arquivo menor de qualidade maior.
echo -e "\033[1;32mSeparando vídeos por tamanhos\033[0m";
ffmpeg -i $2 -an -c:v libx264 -preset veryslow -profile:v high -level 4.2 -b:v 2000k -minrate 2000k -maxrate 2000k -bufsize 4000k -g 96 -keyint_min 96 -sc_threshold 0 -filter:v "scale='trunc(oh*a/2)*2:576'" -pix_fmt yuv420p ./"$separated"/video-2000k.mp4

ffmpeg -i $2 -an -c:v libx264 -preset veryslow -profile:v high -level 4.2 -b:v 1500k -minrate 1500k -maxrate 1500k -bufsize 3000k -g 96 -keyint_min 96 -sc_threshold 0 -filter:v "scale='trunc(oh*a/2)*2:480'" -pix_fmt yuv420p ./"$separated"/video-1500k.mp4

ffmpeg -i $2 -an -c:v libx264 -preset veryslow -profile:v high -level 4.2 -b:v 1000k -minrate 1000k -maxrate 1000k -bufsize 2000k -g 96 -keyint_min 96 -sc_threshold 0 -filter:v "scale='trunc(oh*a/2)*2:360'" -pix_fmt yuv420p ./"$separated"/video-1000k.mp4
   
ffmpeg -i $2 -an -c:v libx264 -preset veryslow -profile:v high -level 4.2 -b:v 700k -minrate 700k -maxrate 700k -bufsize 1400k -g 96 -keyint_min 96 -sc_threshold 0 -filter:v "scale='trunc(oh*a/2)*2:288'" -pix_fmt yuv420p ./"$separated"/video-700k.mp4

ffmpeg -i $2 -an -c:v libx264 -preset veryslow -profile:v high -level 4.2 -b:v 350k -minrate 350k -maxrate 350k -bufsize 700k -g 96 -keyint_min 96 -sc_threshold 0 -filter:v "scale='trunc(oh*a/2)*2:188'" -pix_fmt yuv420p ./"$separated"/video-350k.mp4

echo -e "\033[1;32mIncluindo audio separadamente a cada vídeo convertido\033[0m";

ffmpeg -i ./"$separated"/video-2000k.mp4 -i ./"$separated"/audio.aac -codec copy -shortest ./"$separated"/video+a-2000k.mp4
ffmpeg -i ./"$separated"/video-1500k.mp4 -i ./"$separated"/audio.aac -codec copy -shortest ./"$separated"/video+a-1500k.mp4
ffmpeg -i ./"$separated"/video-1000k.mp4 -i ./"$separated"/audio.aac -codec copy -shortest ./"$separated"/video+a-1000k.mp4
ffmpeg -i ./"$separated"/video-700k.mp4 -i ./"$separated"/audio.aac -codec copy -shortest ./"$separated"/video+a-700k.mp4
ffmpeg -i ./"$separated"/video-350k.mp4 -i ./"$separated"/audio.aac -codec copy -shortest ./"$separated"/video+a-350k.mp4

echo -e "\033[1;32mGerando DASH: time-based templates and SegmentTimeline";

MP4Box -dash 10000 -rap -dash-profile dashavc264:live -bs-switching no -url-template -segment-timeline -segment-name seg_$Bandwidth$_$Time$ ./"$separated"/video+a-2000k.mp4 ./"$separated"/video+a-1500k.mp4 ./"$separated"/video+a-1000k.mp4 ./"$separated"/video+a-700k.mp4 ./"$separated"/video+a-350k.mp4 -out "./$dash/manifest.mp4"

echo -e "\033[1;32mDASH gerado com sucesso em: $dash/manifest.dash\033[0m";
echo -e "\033[1;32mRemovendo diretório $separated\033[0m";
rm -rdf ./$separated
fi #Fim parametro $2 nulo
fi #Fim parametro -make

#Parametro -make2
if [ "$1" = "-make2" ];then
if [ -z "$2" ];then
echo -e "\033[0;31mÉ necessário passar o video.\033[0m";
else
echo -e "\033[1;32mExtraindo audio do vídeo.\033[0m";
separated="_separated";
dash="_dash";
mkdir -p $separated
mkdir -p $dash
ffmpeg -i $2 -vn ./"$separated"/audio.aac
echo -e "\033[1;32mAudio extraido.\033[0m";

#Usando veryslow por conseguir produzir um arquivo menor de qualidade maior.
echo -e "\033[1;32mSeparando vídeos por tamanhos\033[0m";
ffmpeg -i $2 -an -c:v libx264 -preset veryslow -profile:v high -level 4.2 -b:v 2000k -minrate 2000k -maxrate 2000k -bufsize 4000k -g 96 -keyint_min 96 -sc_threshold 0 -filter:v "scale='trunc(oh*a/2)*2:576'" -pix_fmt yuv420p ./"$separated"/video-2000k.mp4

ffmpeg -i $2 -an -c:v libx264 -preset veryslow -profile:v high -level 4.2 -b:v 1500k -minrate 1500k -maxrate 1500k -bufsize 3000k -g 96 -keyint_min 96 -sc_threshold 0 -filter:v "scale='trunc(oh*a/2)*2:480'" -pix_fmt yuv420p ./"$separated"/video-1500k.mp4

ffmpeg -i $2 -an -c:v libx264 -preset veryslow -profile:v high -level 4.2 -b:v 1000k -minrate 1000k -maxrate 1000k -bufsize 2000k -g 96 -keyint_min 96 -sc_threshold 0 -filter:v "scale='trunc(oh*a/2)*2:360'" -pix_fmt yuv420p ./"$separated"/video-1000k.mp4
   
ffmpeg -i $2 -an -c:v libx264 -preset veryslow -profile:v high -level 4.2 -b:v 700k -minrate 700k -maxrate 700k -bufsize 1400k -g 96 -keyint_min 96 -sc_threshold 0 -filter:v "scale='trunc(oh*a/2)*2:288'" -pix_fmt yuv420p ./"$separated"/video-700k.mp4

ffmpeg -i $2 -an -c:v libx264 -preset veryslow -profile:v high -level 4.2 -b:v 350k -minrate 350k -maxrate 350k -bufsize 700k -g 96 -keyint_min 96 -sc_threshold 0 -filter:v "scale='trunc(oh*a/2)*2:188'" -pix_fmt yuv420p ./"$separated"/video-350k.mp4

echo -e "\033[1;32mIncluindo audio separadamente a cada vídeo convertido\033[0m";

ffmpeg -i ./"$separated"/video-2000k.mp4 -i ./"$separated"/audio.aac -codec copy -shortest ./"$separated"/video+a-2000k.mp4
ffmpeg -i ./"$separated"/video-1500k.mp4 -i ./"$separated"/audio.aac -codec copy -shortest ./"$separated"/video+a-1500k.mp4
ffmpeg -i ./"$separated"/video-1000k.mp4 -i ./"$separated"/audio.aac -codec copy -shortest ./"$separated"/video+a-1000k.mp4
ffmpeg -i ./"$separated"/video-700k.mp4 -i ./"$separated"/audio.aac -codec copy -shortest ./"$separated"/video+a-700k.mp4
ffmpeg -i ./"$separated"/video-350k.mp4 -i ./"$separated"/audio.aac -codec copy -shortest ./"$separated"/video+a-350k.mp4

echo -e "\033[1;32mGerando DASH: number-based templates and duration:Bandwidth";

MP4Box -dash 10000 -rap -dash-profile dashavc264:live -bs-switching no -url-template -segment-name seg_$Bandwidth$_$Number$ ./"$separated"/video+a-2000k.mp4 ./"$separated"/video+a-1500k.mp4 ./"$separated"/video+a-1000k.mp4 ./"$separated"/video+a-700k.mp4 ./"$separated"/video+a-350k.mp4 -out "./$dash/manifest.mp4"

echo -e "\033[1;32mDASH gerado com sucesso em: $dash/manifest.dash\033[0m";
echo -e "\033[1;32mRemovendo diretório $separated\033[0m";
rm -rdf ./$separated
fi #Fim parametro $2 nulo
fi #Fim parametro -make2

fi #sem parametro
