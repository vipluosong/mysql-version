mysql_v(){
    # ./Cellar/mariadb@10.1/10.1.36/bin/mysql
    mysql_version=$(ls -al /usr/local/bin/mysql)
    mysql_v_str=${mysql_version#*Cellar/}
    mysql_v=${mysql_v_str%%/*}
}

mysql_list_func(){
    mysql_v
    mysql_list=$(brew list | grep mariadb@)
    for i in $mysql_list
    do
        if [ "$i" = "$mysql_v" ]; then
            echo -e "*\033[41;37m $i \033[0m"
        else
            echo '  '$i;
        fi
    done
}

check_mysql_version(){
    mysql_list_func

    case $1 in
        10.0|10.1|10.3)
            # 第一步：停止当前运行的mysql版本
            # 第二步：删除（/usr/local/Cellar/mariadb）软连接
            # 第三步：创建（/usr/local/Cellar/mariadb）软连接
            # 第四步：删除并创建（brew unlink mariadb@10.1 && brew link mariadb@10.0 --force）软连接
            # 第五步：启动mysql服务（brew services start mariadb@10.0）
            brew services stop $mysql_v

            rm -rf '/usr/local/var/mysql'
            ln -s '/usr/local/var/mysql_'$1 '/usr/local/var/mysql'

            rm -rf '/usr/local/Cellar/mariadb'
            ln -s '/usr/local/Cellar/mariadb@'$1 '/usr/local/Cellar/mariadb'
            
            brew unlink $mysql_v
            brew link mariadb@$1 --force | grep 'Linking'
            brew services start mariadb@$1
            touch /tmp/mysql.sock

            ls -al '/usr/local/var/mysql'
            ls -al '/usr/local/Cellar/mariadb'
            ls -al '/usr/local/bin/mysql'
        ;;

        *) 
            if [ 0"$1" != "0" ]; then
                echo '请输入正确的版本号！';
            fi
    esac

    check_command_mysql_v $1

    if [ 0"$1" != "0" ]; then
        mysql_list_func
        echo '版本切换完成!请在命令行执行 source ~/.zshrc'
    fi
}
get_mysql_v_int(){
    mysql_version=$(mysql -V | sed s/[[:space:]]//g)
    m_v=${mysql_version#*Distrib}
    mysql_v=${m_v%%-MariaDB*}
    mysql_v_int=${mysql_v%.*}
}

check_command_mysql_v(){
    if [ 0"$1" != "0" ]; then
        get_mysql_v_int
        mysql_v_str='mariadb\@'$mysql_v_int
        perl -pi -e "s|$mysql_v_str|mariadb\@$1|gi" ~/.zshrc
    fi
}