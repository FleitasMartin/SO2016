#!/bin/bash

# Variables de entorno

USUARIO=`whoami`
EXTERNALSO="/home/$USUARIO/Documentos/Facultad/SO/Practicas/Entregable1/myShell/externalSO"
RUTA="/bin;/usr/bin;/usr/local/bin;$EXTERNALSO"


# Funciones privadas que sirven de ayuda a las "publicas"

_argumentos(){
    echo "${@/$1}"
}

_dirsReversos(){
    local directorios=(`echo $RUTA | tr ';' '\n'`)
    local indice=$((${#directorios[@]} - 1))
    for (( i=(indice); i >= 0; i-- ))
    do
        echo "${directorios[$i]}"
    done
}

_existeComando(){
    local tipo=`type -t $1`
    if [[ $tipo != '' ]] && [[ $(echo $tipo) == 'function' || $(echo $tipo) == 'builtin' ]] 
    then
        return 0
    else
        local dirsReversos=$(_dirsReversos)
        for dir in ${dirsReversos[@]} 
        do
            if [ -x "${dir}/$1" ]
            then
                return 0
            fi
        done
        return 1
    fi
}

_uidUsuario(){
    echo "$(id -u $USUARIO)"
}

_imprimePromptBase(){
    echo "@$USUARIO>" 
}

_imprimePromptLargo(){
    echo "@YoSoy-$USUARIO>"

}

_imprimePromptUID(){
    echo "@"$(_uidUsuario)"_"$USUARIO">"
}


# Funciones "publicas" de la shell nueva.

ls(){
    _detalleArchivo(){       
        if [ -d $1 ]
        then
            echo $(command ls -dl $1 | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8" "$9}')
        else
            echo $(command ls -l $1 | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8" "$9}')
        fi
    }
    if [[ $1 == '-l' ]]
    then
        local tipos=(`command ls -l | cut -c 1`)
        local permisosOctal=(`stat -c "%a" $(command ls)`) 
        local archivos=(`command ls`)
        for (( i=0; i<${#permisosOctal[@]}; i++))
        do
            echo "${tipos[$i+1]}${permisosOctal[$i]} $(_detalleArchivo ${archivos[$i]})"
        done
    else
        command ls -1   
    fi
}

sl(){
    command ls -r
}

cat(){ #Se redefine por pedido de la catedra aunque no es necesario
    command cat $1 
}

prompt(){
    case $1 in
        largo)
            echo "_imprimePromptLargo"
            ;;
        uid)
            echo "_imprimePromptUID"
            ;;
        *)
            echo "_imprimePromptBase"
            ;;
    esac
}

pwd(){ #Se redefine por pedido de la catedra aunque no es necesario
    command pwd  
}

tac(){
    local contenido=(`cat $1`)
    for (( i=${#contenido[@]}; i>=0; i--))
    do
        echo "${contenido[$i]}"
    done
}

quiensoy(){
    if [ $# -eq 1 ]
    then
        case $1 in
            +h)
                echo "Yo soy $USUARIO y estoy en la maquina '$(hostname)'" 
                ;;
            +inos)
                echo "Yo soy $USUARIO y tengo UID=$(id -u $USUARIO)"
                ;;
            *)
                echo "Yo soy $USUARIO"
                ;;
        esac
    else
        echo "Cantidad de argumentos incorrecta. Solo es posible recibir uno solo." 
    fi
}

mkdir(){
    _puedoEscribir(){
        if [ -w `dirname $1` ]
        then
            return 0
        else
            return 1
        fi
    }
    local path=$1
    local args=$(_argumentos $*)
    if _puedoEscribir $path 
    then
        command mkdir $args $path 2> /dev/null || echo "Error, Directorio/s no creado/s"
    else
        echo "No tenés permiso!"
    fi
}

# Las siguientes tres funciones se agregaron para acceder mediante el comando eval a los scripts agregados.

serverNC(){
    source "$EXTERNALSO/serverNC"
}

clienteNC(){
    source "$EXTERNALSO/clienteNC"
}

scanner(){
    source "$EXTERNALSO/scanner"
}

# Variable que contiene el prompt del usuario.
prompt=_imprimePromptBase 

while true; do

    read -r -p `eval $prompt` input 
    if [ -z "$input" ]
    then
        echo "<<--SIN-COMANDOS-->>"
        continue
    fi   
    
    comando=($input)
    argumentos=$(_argumentos $input)
    
    if _existeComando $comando
    then
        case $comando in
            prompt)
                prompt=$(eval "$comando $argumentos" &)
                wait $!
                ;;
            *)
                eval "$comando $argumentos" #& #con el ampersand no funciona correctamente el comando cd 
                wait $!
                ;;
        esac
    else
        echo "No se encontró el programa '$comando'"
    fi   
    
done
