// SPDX-License-Identifier: CC-BY-4.0
pragma solidity 0.8.4;

contract licitacao{

// Tente descrever aqui o funcionamento do seu contrato
// o contrato aceita vários licitantes

// Lance[] public Lance;   >>> o struct Lance não foi definido, vc quer dizer Oferta[] public Lance; 

    struct Oferta {
        string nomeDolicitante;
        address payable enderecoLicitante;
        uint valorDolance;
        bool jaFoiDesclassificado;  // true = sim  ou  false = não
    }
    
    address payable public contaGovernamental;
    address public enderecoCarteiraLicitanteVencedor;
    uint public prazoFinalLeilao;

        uint public menorLance;
    
    Oferta[] public lances;  // precisamos corrigir logo isso 

    bool public encerrado;

    event novoMenorLance(address nomeDolicitante, uint valor);
    event fimDoPregao(address enderecoLicitante, uint valor);

    modifier somenteGoverno {
        require(msg.sender == contaGovernamental, "Somente Governo pode realizar essa operacao");
//      Este _ significa dizer para a EVM (Ethereum Virtual Machine) continuar a executar o que vem na 
//      sequencia na clausula caso o requirimento acima tenha sido atendido
        _;
    }

    constructor(
        uint _duracaoPregao,
        address payable _contaGovernamental
    ) {
        contaGovernamental = _contaGovernamental;
        prazoFinalLeilao = block.timestamp + _duracaoPregao;
    }


    function lance(string memory nomeDolicitante, address payable enderecoCarteiraLicitante) public payable {
        require(block.timestamp <= prazoFinalLeilao, "Leilao encerrado.");
        require(msg.value < menorLance, "Ja foram apresentados lances menores.");
        
        menorLance = msg.value;
        enderecoCarteiraLicitanteVencedor = msg.sender;
        
        //Realizo estorno das ofertas aos perdedores
        /*
        For é composto por 3 parametros (separados por ponto virgula)
            1o  é o inicializador do indice
            2o  é a condição que será checada para saber se o continua 
                o loop ou não 
            3o  é o incrementador (ou decrementador) do indice
        */
        for (uint i=0; i<lances.length; i++) {
            Oferta storage ofertaPerdedora = lances[i];
            //   !ofertantePerdedor.jaFoiReembolsado é uma expressão mais curta para checar se a condição é falsa
            //   é o mesmo que escrever ofertantePerdedor.jaFoiReembolsado == false 
            if (!ofertaPerdedora.jaFoiDesclassificado) {
                ofertaPerdedora.enderecoLicitante.transfer(ofertaPerdedora.valorDolance);
                ofertaPerdedora.jaFoiDesclassificado = true;
            }
        }
        
        //Crio o ofertante
        Oferta memory ofertaVencedoraTemporaria = Oferta(nomeDolicitante, enderecoCarteiraLicitante, msg.value, false);
        
        //Adiciono o novo concorrente vencedor temporario no array de ofertantes
        lances.push(ofertaVencedoraTemporaria);
        
        
        emit novoMenorLance (msg.sender, msg.value);
    }

   
    function finalizaLeilao() public somenteGoverno {
       
        require(block.timestamp >= prazoFinalLeilao, "Leilao ainda nao encerrado.");
        //   !encerrado é uma expressão mais curta para checar se a condição é falsa
        //   é o mesmo que escrever encerrado == false 
        require(!encerrado, "Leilao encerrado.");

        encerrado = true;
        emit fimDoPregao(enderecoCarteiraLicitanteVencedor, menorLance);

        contaGovernamental.transfer(address(this).balance);
    }
    
    function melhorLicitante() public view somenteGoverno returns (address) {
        return enderecoCarteiraLicitanteVencedor;
    }
}
