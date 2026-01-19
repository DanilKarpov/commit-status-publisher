<%@ include file="include-internal.jsp" %>
<jsp:useBean id="chainId" type="java.lang.String" scope="request"/>
<jsp:useBean id="statusJSON" type="java.lang.String" scope="request"/>

<c:set var="blockId" value="block_${chainId}"/>

<script type="text/javascript">
  if ($('${blockId}') && $('status_${chainId}')) {
    BS.PieStatus.drawCarpetPieChart("BS.BuildChains._showChain($j('#${blockId}')[0])", $('status_${chainId}'), ${statusJSON});
  }
</script>
