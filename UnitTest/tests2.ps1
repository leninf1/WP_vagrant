function unit_tests_on_vm {
    $VAGRANT_CMD = Get-Command vagrant -ErrorAction SilentlyContinue

    if ($null -eq $VAGRANT_CMD) {
        Write-Output "No se encontró el comando vagrant en el sistema"
        exit 1
    }

    $env:TESTS = "true"

    Write-Output "`n########## Ejecutando las pruebas unitarias en una VM ##########"

    & $VAGRANT_CMD up

    # Ejecutar las pruebas
    & $VAGRANT_CMD ssh -c "cd /vagrant/cookbooks/database && chef exec rspec --format=documentation"
    & $VAGRANT_CMD ssh -c "cd /vagrant/cookbooks/wordpress && chef exec rspec --format=documentation"
    & $VAGRANT_CMD ssh -c "cd /vagrant/cookbooks/proxy && chef exec rspec --format=documentation"

    Write-Output "`n########## Destruyendo la máquina virtual ##########"

    # Destruir todas las máquinas virtuales
    $destroyResult = & $VAGRANT_CMD destroy -f
    if ($destroyResult -match "There was an error") {
        Write-Output "Hubo un error al intentar destruir la máquina virtual."
        exit 1
    }

    # Destruir la máquina virtual
    #& $VAGRANT_CMD destroy -f test

    # Limpiar la variable de entorno
    Remove-Item Env:\TESTS

    Write-Output "########## Fin de las pruebas unitarias en una VM ##########"
}

function run_tests_on_a_container {
    $DOCKER_CMD = Get-Command docker -ErrorAction SilentlyContinue
    $DOCKER_IMAGE = "cppmx/chefdk:latest"
    $TEST_CMD = "chef exec rspec --format=documentation"

    if ($null -eq $DOCKER_CMD) {
        Write-Output "No se encontró el comando docker en el sistema"
        exit 1
    }

    & $DOCKER_CMD run --rm -v (Get-Location):/cookbooks $DOCKER_IMAGE $TEST_CMD
}

function unit_tests_on_a_container {
    $DATABASE = Join-Path (Get-Location) "cookbooks\database"
    $WORDPRESS = Join-Path (Get-Location) "cookbooks\wordpress"
    $PROXY = Join-Path (Get-Location) "cookbooks\proxy"

    Write-Output "`n########## Ejecutando las pruebas unitarias en Docker ##########"

    Write-Output "Probando las recetas de Database"
    run_tests_on_a_container $DATABASE

    Write-Output "Probando las recetas de Wordpress"
    run_tests_on_a_container $WORDPRESS

    Write-Output "Probando las recetas de Proxy"
    run_tests_on_a_container $PROXY

    Write-Output "########## Fin de las pruebas unitarias en Docker ##########"
}

function itg_tests {
    $KITCHEN_CMD = Get-Command kitchen -ErrorAction SilentlyContinue
    #Ejecutamos las pruebas
    Write-Output "Creando las maquinas"
    Set-Location $args[0]
    & $KITCHEN_CMD test
    #Eliminamos las vm's
    Write-Output "Limpiando el entorno de pruebas"
    Set-Location $args[0]
    & $KITCHEN_CMD destroy
}

function all_itg_tests {
    $rutaactual = Get-Location
    #establecer la ruta de las recetas
    $parent = Split-Path ($rutaactual) -Parent
    $COOKBOOKS = Join-Path ($parent) "cookbooks"
    Write-Output ""
    Write-Output "Iniciando las pruebas de base de datos"
    #itg_tests $COOKBOOKS\database
    Write-Output "Iniciando las pruebas de wordpress"
    itg_tests $COOKBOOKS\wordpress
    Write-Output "Iniciando las pruebas de base de proxy"
    itg_tests $COOKBOOKS\proxy
    Write-Output "Pruebas finalizadas"
    #Retornamos a la carpeta inicial
    Set-Location $rutaactual
}

function manual {
    # Menú de inicio
    Write-Output "Seleccione una opción:"
    Write-Output "1. Ejecutar pruebas unitarias en una VM"
    Write-Output "2. Ejecutar pruebas unitarias en un contenedor"
    Write-Output "3. Ejecutar pruebas de integración e infraestructura"
    Write-Output "4. Salir"
    $OPTION = Read-Host "Opción: "

    switch ($OPTION) {
        1 { unit_tests_on_vm }
        2 { unit_tests_on_a_container }
        3 { all_itg_tests }
        4 { Write-Output "Hasta luego :)" ; exit 0 }
        default { Write-Output "Opción inválida. Saliendo..." }
    }
}

if (-not $args) {
    manual
} elseif ($args[0] -eq "vm") {
    unit_tests_on_vm
} elseif ($args[0] -eq "docker") {
    unit_tests_on_a_container
} elseif ($args[0] -eq "database") {
    itg_tests (Get-Location)\cookbooks\database
} elseif ($args[0] -eq "wordpress") {
    itg_tests (Get-Location)\cookbooks\wordpress
} elseif ($args[0] -eq "proxy") {
    itg_tests (Get-Location)\cookbooks\proxy
} else {
    Write-Output "Opción inválida"
    exit 1
}